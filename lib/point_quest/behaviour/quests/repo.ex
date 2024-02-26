defmodule PointQuest.Behaviour.Quests.Repo do
  alias PointQuest.Quests.Event
  alias PointQuest.Quests.Quest

  @callback write(Quest.t(), Event.QuestStarted.t()) :: {:ok, Quest.t()}
  @callback get_quest_by_id(quest_id :: String.t()) ::
              {:ok, Quest.t()} | {:error, :quest_not_found}
end
