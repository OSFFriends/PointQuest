defmodule Infra.Linear.Records.Issue do
  @moduledoc """
  A Linear issue object.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.Comment
  alias Infra.Linear.Records.Cycle
  alias Infra.Linear.Records.Label
  alias Infra.Linear.Records.Project
  alias Infra.Linear.Records.WorkflowState
  alias Infra.Linear.Records.User

  # assignee: User
  # attachments (linked issues?): [Issue]
  # boardOrder
  # children: [Issue]
  # dueDate: DateTime (although says timeless?)
  # history: IssueHistoryConnection TODO: PQ-5
  # identifier: human readable id string
  # inverseRelations: IssueRelationConnection TODO: PQ-6
  # parent: Issue
  # priorityLabel (maybe?): String
  # projectMilestones: ProjectMilestones TODO: PQ-9
  # relations: IssueRelationConnection
  # sortOrder: Float

  @type full_issue :: %__MODULE__{
          id: String.t(),
          identifier: String.t(),
          branchName: String.t(),
          comments: [Comment.t()],
          createdAt: DateTime.t(),
          creator: User.t(),
          cycle: Cycle.t(),
          description: String.t(),
          estimate: Float.t(),
          labels: [Label.t()],
          priority: Float.t(),
          project: Project.t(),
          state: WorkflowState.issue_status(),
          title: String.t(),
          url: String.t()
        }

  @type issue_card :: %__MODULE__{
          id: String.t(),
          identifier: String.t(),
          title: String.t()
        }

  @type t :: full_issue | issue_card

  object do
    field :id, :string
    field :identifier, :string
    field :branchName, :string
    nodes(:comments, Comment)
    field :createdAt, :utc_datetime
    embed(:creator, User)
    embed(:cycle, Cycle)
    field :description, :string
    field :estimate, :float
    nodes(:labels, Label)
    field :priority, :float
    embed(:project, Project)
    embed(:state, WorkflowState)
    field :title, :string
    field :url, :string
  end
end
