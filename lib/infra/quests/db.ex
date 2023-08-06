defmodule Infra.Quests.Db do
  @moduledoc """
  In-memory DB system
  """

  alias PointQuest.Quests.Quest

  @spec create(quest :: Ecto.Changeset.t(PointQuest.Quests.Quest)) :: Quest.t()
  def create(quest) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest, :insert) do
      quest = Map.put(quest, :id, Ecto.UUID.generate())
      {:ok, _pid} = Infra.Quests.QuestServer.start_link(quest)
      quest
    end
  end

  def update(quest) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest, :update) do
      server = lookup_quest_server(quest.id)
      :ok = Agent.update(server, fn _q -> quest end)
      {:ok, quest}
    end
  end

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
