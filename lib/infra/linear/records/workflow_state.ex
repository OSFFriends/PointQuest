defmodule Infra.Linear.Records.WorkflowState do
  @moduledoc """
  The state a Linear issue is in (status of the ticket).

  For example, common states are "In Progress", "Done", "Backlog", etc.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.Issue

  @type issue_status :: %__MODULE__{
          id: String.t(),
          issues: nil,
          name: String.t(),
          position: Float.t()
        }

  @type queried_workflow_state :: %__MODULE__{
          id: String.t(),
          issues: [Issue.t()],
          name: String.t(),
          position: Float.t()
        }

  @type t :: issue_status | queried_workflow_state

  object do
    field :id, :string
    embed(:issues, Issue)
    field :name, :string
    field :position, :float
  end
end
