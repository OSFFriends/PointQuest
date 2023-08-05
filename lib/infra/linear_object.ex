defmodule Infra.LinearObject do
  @moduledoc """
  expands Linear objects under "nodes" keys 
  """
  alias __MODULE__

  defmacro __using__(_opts) do
    quote do
      import LinearObject

      Module.register_attribute(__MODULE__, :schema_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :nodes, accumulate: true)
      Module.register_attribute(__MODULE__, :embeds, accumulate: true)
    end
  end

  defmacro object(do: block) do
    quote do
      unquote(block)

      defstruct Enum.reverse(@struct_fields)

      @spec __schema__() :: keyword()
      def __schema__(), do: @schema_fields

      @spec __nodes__() :: keyword()
      def __nodes__(), do: @nodes

      @spec __embeds__() :: keyword()
      def __embeds__(), do: @embeds
    end
  end

  @doc """
  Adds a field to a Stripe Object.

  `field` is similar to `Ecto.Schema.field` and defines simple fields on a
  Stripe Object.

  ```elixir
  defmodule MyApp.Stripe.Invoice do
    use Infra.Stripe.API.StripeObject

    object do
      field :id, :string
      field :auto_advance, :boolean
      field :metadata, :map
    end
  end
  ```
  """
  defmacro field(name, type \\ :string, opts \\ []) do
    quote do
      LinearObject.__define_field__(
        __MODULE__,
        :field,
        {unquote(name), unquote(type)},
        unquote(opts)
      )
    end
  end

  @doc """
  Adds an `expandable` field definition to Stripe Object.

  See module documentation for additional information on `expandables`.

  ```elixir
  defmodule MyApp.Stripe.Invoice do
    use Infra.LinearObject

    object do
      nodes :charge, MyApp.Stripe.Charge
      nodes :customer, MyApp.Stripe.Customer
    end
  end
  ```
  """
  defmacro nodes(name, type) do
    quote do
      LinearObject.__define_field__(__MODULE__, :nodes, {unquote(name), unquote(type)}, [])
    end
  end

  @doc """
  Adds `embed` field definition to Stripe Object.

  See module documentation for additional information on `embeds`.

  ```elixir
  defmodule MyApp.Stripe.Invoice do
    use Infra.LinearObject

    object do
      embed :lines, MyApp.Stripe.Invoice.Line
    end
  end
  ```
  """
  defmacro embed(name, type) do
    quote do
      LinearObject.__define_field__(__MODULE__, :embed, {unquote(name), unquote(type)}, [])
    end
  end

  @spec load(module(), [map()]) :: [struct()]
  @doc """
  Load `data` through Linear `object`.

  This will typecast `data` based on the `object` definition supplied.
  """
  def load(object, data) when is_list(data) do
    Enum.map(data, &load(object, &1))
  end

  @spec load(module(), nil) :: nil
  def load(_object, nil), do: nil

  @spec load(module(), map()) :: struct()
  def load(object, data) do
    local_fields =
      object.__schema__()
      |> Enum.reduce(%{}, fn {key, type}, accum ->
        param_value = get_key(data, key)
        {:ok, casted} = Ecto.Type.cast(type, param_value)
        Map.put(accum, key, casted)
      end)

    nodes =
      object.__nodes__()
      |> Enum.reduce(%{}, fn {key, node_object}, accum ->
        nestable_params = get_key(data, key)
        expanded = load_nodes(node_object, nestable_params)
        Map.put(accum, key, expanded)
      end)

    embeds =
      object.__embeds__()
      |> Enum.reduce(%{}, fn {key, embedded_object}, accum ->
        nestable_params = get_key(data, key)
        embed = load(embedded_object, nestable_params)
        Map.put(accum, key, embed)
      end)

    params =
      Enum.concat([local_fields, nodes, embeds])
      |> Enum.reduce(%{}, fn {key, value}, accum ->
        Map.put(accum, key, value)
      end)

    struct(object, params)
  end

  @spec __define_field__(module(), :nodes | :embed | :field, {atom(), module()}, keyword()) :: :ok
  def __define_field__(module, :nodes, {name, nodes}, opts) do
    Module.put_attribute(module, :struct_fields, {name, Keyword.get(opts, :default)})
    Module.put_attribute(module, :nodes, {name, nodes})
  end

  def __define_field__(module, :embed, {name, type}, opts) do
    Module.put_attribute(module, :struct_fields, {name, Keyword.get(opts, :default)})
    Module.put_attribute(module, :embeds, {name, type})
  end

  def __define_field__(module, :field, {name, type}, opts) do
    type = get_field_type(module, name, type, opts)
    Module.put_attribute(module, :struct_fields, {name, Keyword.get(opts, :default)})
    Module.put_attribute(module, :schema_fields, {name, type})
  end

  # Figure out type field definition is and return in format `Ecto.Type.cast/2`able.
  # * base type
  # * composite type
  # * Custom type
  # * parameterized Type
  defp get_field_type(mod, name, type, opts) do
    cond do
      # field {:array, [type]} support
      composite?(type) ->
        {outer_type, inner_type} = type
        {outer_type, get_field_type(mod, name, inner_type, opts)}

      # field :name, :utc_datetime (or any other base type)
      Ecto.Type.base?(type) ->
        type

      Code.ensure_compiled(type) == {:module, type} ->
        cond do
          # field :uri, URI (custom ecto type support)
          function_exported?(type, :type, 0) ->
            type

          # field :status, Ecto.Enum, values: [:open, :closed] (parameterized type support)
          function_exported?(type, :type, 1) ->
            Ecto.ParameterizedType.init(type, Keyword.merge(opts, field: name, schema: mod))
        end
    end
  end

  @spec get(struct(), [atom(), ...]) :: any()
  @doc """
  Helper for pulling value out of `StripeObject` at a given path - similar to
  `Kernel.get_in/2`.

  > Getting a value at a path that contains a list is not supported.

  ```elixir
  StripeObject.get(stripe_object, [:billing, :address])
  ```
  """
  def get(record, []) do
    record
  end  

  def get(record, [head | rest]) when is_list(record) and is_integer(head) do
    get(Enum.at(record, head), rest)
  end

  def get(record, _path) when is_list(record) do
    raise ArgumentError, "LinearObject.get/2 cannot get paths containing lists"
  end

  def get(nil, _path) do
    nil
  end

  def get(record, [key | rest]) do
    get(Map.get(record, key), rest)
  end

  defp load_nodes(node, params) do
    params = get_key(params, :nodes)
    load(node, params)
  end

  defp composite?({composite, _}) do
    Ecto.Type.composite?(composite)
  end

  defp composite?(_type), do: false

  defp get_key(map, atom_key) do
    # try to get key as atom and fall back to string version
    Map.get(map, atom_key, Map.get(map, Atom.to_string(atom_key)))
  end
end
