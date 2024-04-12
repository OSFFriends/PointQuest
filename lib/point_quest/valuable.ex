defmodule PointQuest.Valuable do
  @moduledoc """
  Wrapper for `Ecto.Schema` for building value objects.

  Value objects are simple structs that are used as values - such as `Command`
  and `Event` records. By wrapping Ecto we are able to leverage its schema and
  changeset API in order to have type checking and validation in custom
  constructors.

  ## Constructors

  Given a schema declaration such as:

  ```elixir
  defmodule PointQuest.Command do
    use PointQuest.Valuable

    embedded_schema do
      field :name, :string
      field :age, :integer
      embeds_one :contact, Contact
    end
  end
  ```

  We now have `new/1` and `new!/1` functions available to construct one of
  these records. Where `new/1` will return a tuple of the result or error and
  `new!` will throw if invalid.

  ```elixir
  {:ok, %PointQuest.Command{}} = PointQuest.Command.new(%{name: "Stephen", age: "55", contact: %{phone: "555-555-5555"}})
  %PointQuest.Command{} = PointQuest.Command.new!(%{name: "Stephen", age: "55", contact: %{phone: "555-555-5555"}})
  ```

  ## Customizing defaults and required values

  By default all fields on the schema will be considered as mandatory. To
  specify fields as optional include the `optional_fields` value.

  ```elixir
  defmodule PointQuest.Command do
    use PointQuest.Valuable, optional_fields: [:age]

    embedded_schema do
      field :name, :string
      field :age, :integer
      embeds_one :contact, Contact
    end
  end
  ```

  To further customize validation a `changeset/2` function can be defined which the constructors call into.

  ```elixir
  defmodule PointQuest.Command do
    use PointQuest.Valuable

    embedded_schema do
      field :name, :string
      field :age, :integer
      field :occupation, :string
      embeds_one :contact, Contact
    end

    def changeset(command, params) do
      command
      |> change(occupation: "programmer")
      |> cast(params, [:age, :name, :occupation])
      |> validate_required([:age, :name, :occupation])
    end
  end
  ```
  """

  defmacro __using__(opts) do
    optional_fields = Keyword.get(opts, :optional_fields, [])

    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import PointQuest.Valuable

      def new!(params) do
        struct(__MODULE__)
        |> changeset(params)
        |> apply_action!(:insert)
      end

      def new(params) do
        struct(__MODULE__)
        |> changeset(params)
        |> apply_action(:insert)
      end

      def changeset(valuable, params \\ %{}) do
        local_fields = __schema__(:fields) -- __schema__(:embeds)

        local_changeset =
          valuable
          |> cast(params, local_fields)
          |> validate_required(local_fields -- unquote(optional_fields))

        Enum.reduce(__schema__(:embeds), local_changeset, fn embed, changeset ->
          changeset
          |> cast_embed(embed, required: embed not in unquote(optional_fields))
        end)
      end

      defoverridable changeset: 1
      defoverridable changeset: 2
    end
  end
end
