defmodule Infra.Linear.Records.Label do
  @moduledoc """
  A linear label, used to group similar issues.
  """

  use Infra.LinearObject

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  object do
    field :id, :string
    field :name, :string
  end
end
