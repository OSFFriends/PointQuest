defmodule Infra.Quests.Db do
  @moduledoc """
  In-memory DB system
  """
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias Infra.Quests.QuestServer
  alias PointQuest.Quests.Event

  @impl PointQuest.Behaviour.Quests.Repo
  def write(quest, %Event.QuestStarted{quest_id: quest_id}) do
    quest = Map.put(quest, :id, quest_id)

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Infra.Quests.QuestSupervisor,
        {QuestServer, quest: quest}
      )

    {:ok, quest}
  end

  def write(quest, %Event.AdventurerJoinedParty{}) do
    server = lookup_quest_server(quest.id)
    :ok = QuestServer.update(server, quest)

    {:ok, quest}
  end

  def update(quest_changeset) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :update) do
      server = lookup_quest_server(quest.id)
      :ok = QuestServer.update(server, quest)
      {:ok, quest}
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        {:error, :quest_not_found}

      pid ->
        {:ok, QuestServer.get(pid)}
    end
  end

  defp lookup_quest_server(quest_id) do
    case Registry.lookup(Infra.Quests.Registry, quest_id) do
      [{pid, _state}] ->
        pid

      _not_found ->
        nil
    end
  end
end
