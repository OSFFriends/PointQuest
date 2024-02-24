defmodule Infra.Linear.Records.Cycle do
  @moduledoc """
  A linear cycle, used to constrain the current sprint of work.
  """

  use Infra.LinearObject

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          number: Float.t()
        }

  object do
    field :id, :string
    field :name, :string
    field :number, :float
  end
end
