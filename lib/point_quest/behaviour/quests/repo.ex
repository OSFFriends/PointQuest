defmodule PointQuest.Behaviour.Quests.Repo do
  alias PointQuest.Error
  alias PointQuest.Quests
  alias PointQuest.Quests.Event

  @callback write(Quests.Quest.t(), Event.QuestStarted.t()) :: :ok
  @callback get_quest_by_id(quest_id :: String.t()) ::
              {:ok, Quests.Quest.t()} | {:error, Error.NotFound.t(:quest)}
  @callback get_adventurer_by_id(quest_id :: String.t(), adventurer_id :: String.t()) ::
              {:ok, Quests.Adventurer.t()} | {:error, Error.NotFound.t(:adventurer | :quest)}
  @callback get_party_leader_by_id(quest_id :: String.t(), leader_id: String.t()) ::
              {:ok, Quests.PartyLeader.t()} | {:error, Error.NotFound.t(:quest)}
  @callback get_all_adventurers(quest_id :: String.t()) ::
              {:ok, [Quests.Adventurer.t()]} | {:error, Error.NotFound.t(:quest)}
end
