defmodule Infra.Linear.Records.Project do
  @moduledoc """
  A linear project, used to group "buckets" of issues.
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
