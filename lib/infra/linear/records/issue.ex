defmodule Infra.Linear.Records.Issue do
  @moduledoc """
  A Linear issue object.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.Comment
  alias Infra.Linear.Records.User

  @type issue :: %__MODULE__{
          id: String.t(),
          branchName: String.t(),
          comments: [Comment.t()],
          createdAt: DateTime.t(),
          creator: User.t(),
          description: String.t(),
          estimate: Float.t(),
          priority: Float.t(),
          title: String.t(),
          url: String.t()
        }

  object do
    field :id, :string
    field :branchName, :string
    nodes :comments, Comment
    field :createdAt, :utc_datetime
    embed :creator, User
    field :description, :string
    field :estimate, :float
    field :priority, :float
    field :title, :string
    field :url, :string
  end
end
