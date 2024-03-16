defmodule PointQuest.Behaviour.Quests.Repo do
  alias PointQuest.Quests.Event
  alias PointQuest.Quests

  @callback write(Quests.Quest.t(), Event.QuestStarted.t()) :: {:ok, Quest.t()}
  @callback get_quest_by_id(quest_id :: String.t()) ::
              {:ok, Quests.Quest.t()} | {:error, :quest_not_found}
  @callback get_adventurer_by_id(quest_id :: String.t(), adventurer_id :: String.t()) ::
              {:ok, Quests.Adventurer.t()} | {:error, :adventurer_not_found | :quest_not_found}
  @callback get_party_leader_by_id(quest_id :: String.t(), leader_id: String.t()) ::
              {:ok, Quests.PartyLeader.t()} | {:error, :quest_not_found}
end
