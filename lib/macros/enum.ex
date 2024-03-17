defmodule PointQuest.Macros.Enum do
  @moduledoc """
  Extends EctoEnum's `defenum` macro with our own custom helpers.
  Importing this module should be preferred over `EctoEnum` directly.
  """
  defmacro defenum(module, _type, enum_values) do
    quote do
      defmodule unquote(module) do
        use EctoEnum, unquote(enum_values) |> Enum.map(&{&1, to_string(&1)})

        @spec valid_atoms() :: list(unquote(module).t())
        def valid_atoms() do
          unquote(module).__valid_values__() |> Enum.filter(&is_atom/1)
        end

        @spec to_enum_atom(binary) :: list(unquote(module).t())
        def to_enum_atom(string) do
          Enum.find(valid_atoms(), string, &(to_string(&1) == string))
        end
      end
    end
  end
end
