defmodule PointQuest.Behaviour.Quests.Repo do
  alias Ecto.Changeset
  alias PointQuest.Quests.Quest

  @callback create(Ecto.Changeset.t(Quest.t())) :: {:ok, Quest.t()} | {:error, Changeset.t()}
  @callback update(Ecto.Changeset.t(Quest.t())) :: {:ok, Quest.t()}
  @callback get_quest_by_id(quest_id :: String.t()) ::
              {:ok, Quest.t()} | {:error, :quest_not_found}
end
