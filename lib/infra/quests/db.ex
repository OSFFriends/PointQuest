defmodule Infra.Quests.Db do
  @moduledoc """
  In-memory DB system
  """
  @behaviour PointQuest.Behaviour.Quests.Repo

  @impl PointQuest.Behaviour.Quests.Repo
  def create(quest_changeset) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :insert) do
      quest = Map.put(quest, :id, Ecto.UUID.generate())
      {:ok, _pid} = Infra.Quests.QuestServer.start_link(quest)
      {:ok, quest}
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def update(quest_changeset) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :update) do
      server = lookup_quest_server(quest.id)
      :ok = Agent.update(server, fn _q -> quest end)
      {:ok, quest}
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        {:error, :quest_not_found}

      pid ->
        {:ok, Agent.get(pid, fn q -> q end)}
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
