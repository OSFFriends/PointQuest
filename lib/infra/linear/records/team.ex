defmodule Infra.Linear.Records.Team do
  @moduledoc """
  A Linear team object.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.Issue

  @type team :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          issues: [Issue.t()]
        }

  object do
    field :id, :string
    field :name, :string
    nodes :issues, Issue
  end
end
