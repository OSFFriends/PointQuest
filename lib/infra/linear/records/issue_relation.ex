defmodule Infra.Linear.Records.IssueRelation do
  @moduledoc """
  Maps the relationship between issues.

  Type contains data on how the issues are related.

  Please be aware that due to Linear's data modelling for issue relationships,
  both `Relations` and `InverseRelations` might describe the same relationship
  between 2 issues from opposite perspectives.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.Issue

  @type t :: %__MODULE__{
          issue: Issue.issue_card(),
          relatedIssue: Issue.issue_card(),
          type: String.t()
        }

  object do
    embed(:issue, Issue)
    embed(:relatedIssue, Issue)
    field :type, :string
  end
end
