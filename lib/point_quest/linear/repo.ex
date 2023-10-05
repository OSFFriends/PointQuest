defmodule PointQuest.Linear.Repo do
  @behaviour PointQuest.Behaviour.Linear.Repo

  alias PointQuest.Repo
  alias Infra.Linear.Records.Token

  @impl PointQuest.Behaviour.Linear.Repo
  def get_token_for_user(user_id) do
    Repo.get_by(Token, user_id: user_id)
  end

  def insert_token(changeset) do
    Repo.insert(changeset)
  end
end
