defmodule Infra.Linear.Records.Comment do
  @moduledoc """
  A Linear comment object.
  """

  use Infra.LinearObject

  alias Infra.Linear.Records.User

  @type comment :: %__MODULE__{
          id: String.t(),
          body: String.t(),
          createdAt: DateTime.t(),
          url: String.t(),
          user: User.t()
        }

  object do
    field :id, :string
    field :body, :string
    field :createdAt, :utc_datetime
    field :url, :string
    embed(:user, User)
  end
end
