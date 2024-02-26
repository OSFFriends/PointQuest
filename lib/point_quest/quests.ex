defmodule PointQuest.Quests do
  @moduledoc """
  Client for quest interactions
  """
  @behaviour PointQuest.Behaviour.Quest

  alias PointQuest.Quests.Event
  alias PointQuest.Quests.Quest

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  @impl PointQuest.Behaviour.Quest
  def create(quest_params) do
    quest_changeset = Quest.create_changeset(%Quest{}, quest_params)

    with {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :insert) do
      repo().write(
        quest,
        Event.QuestStarted.new!(%{
          name: quest.name,
          party_leader: Ecto.embedded_dump(quest.party_leader, :json)
        })
      )
    end
  end

  @impl PointQuest.Behaviour.Quest
  def get(quest_id) do
    repo().get_quest_by_id(quest_id)
  end

  @impl PointQuest.Behaviour.Quest
  def add_adventurer_to_party(quest_id, adventurer_params) do
    with {:ok, quest} <- Infra.Quests.Db.get_quest_by_id(quest_id),
         quest_changeset <- Quest.add_adventurer_to_party_changeset(quest, adventurer_params),
         {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :update) do
      new_adventurer = List.last(quest.adventurers)

      repo().write(
        quest,
        Event.AdventurerJoinedParty.new!(
          Map.put(Ecto.embedded_dump(new_adventurer, :json), :quest_id, quest_id)
        )
      )
    end
  end
end
