defmodule PointQuest.Error.NotFound do
  @moduledoc """
  Error for when a resource cannot be found.

  ```elixir
  Error.NotFound.exception(resource: :quest)
  ```
  """

  @type t(resource) :: %__MODULE__{
          resource: resource,
          message: String.t()
        }

  @type t :: %__MODULE__{
          resource: any() | nil,
          message: String.t()
        }

  defexception [:message, :resource]

  @doc """
  Return error when `resource` cannot be found

  ```elixir
  %PointQuest.Error.NotFound{resource: :quest, message: ":quest not found"} = PointQuest.Error.NotFound.exception(resource: :quest)
  ```
  """
  def exception(opts) do
    %__MODULE__{
      resource: opts[:resource],
      message: "#{inspect(opts[:resource])} not found"
    }
  end
end
