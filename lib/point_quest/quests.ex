defmodule PointQuest.Quests do
  @moduledoc """
  Client for quest interactions
  """

  alias PointQuest.Quests.Quest

  def create(quest_params) do
    %Quest{}
    |> Quest.create_changeset(quest_params)
    |> Infra.Quests.Db.create()
  end

  def add_adventurer_to_party(quest_id, adventurer_params) do
    with {:ok, quest} <- Infra.Quests.Db.get_quest_by_id(quest_id) do
      Quest.add_adventurer_to_party_changeset(quest, adventurer_params)
      |> Infra.Quests.Db.update()
    end
  end
end
