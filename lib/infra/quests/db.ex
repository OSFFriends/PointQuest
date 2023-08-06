defmodule Infra.Quests.Db do
  @moduledoc """
  In-memory DB system
  """
  alias PointQuest.Quests.Quest

  @spec create_quest(Ecto.Changeset.t(Quest.t())) :: Quest.t()
  def create_quest(quest_changeset) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :insert) do
      quest =
        Map.put(quest, :id, Ecto.UUID.generate())
        |> Map.put(
          :adventurers,
          reduce_adventurers(quest.adventurers)
        )

      {:ok, _pid} = Infra.Quests.QuestServer.start_link(quest)
      quest
    end
  end

  @spec update_quest(Ecto.Changeset.t(Quest.t())) :: {:ok, Quest.t()}
  def update_quest(quest_changeset) do
    with {:ok, quest} <- Ecto.Changeset.apply_action(quest_changeset, :update) do
      quest_server = lookup_quest_server(quest.id)

      quest = Map.put(quest, :adventurers, reduce_adventurers(quest.adventurers))
      :ok = Agent.update(quest_server, fn _q -> quest end)
      {:ok, quest}
    end
  end

  @spec get_quest_by_id(quest_id :: String.t()) :: {:ok, Quest.t()} | {:error, :quest_not_found}
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        {:error, :quest_not_found}

      pid ->
        {:ok, Agent.get(pid, fn q -> q end)}
    end
  end

  @spec reduce_adventurers(adventurers :: [Adventurer.t()]) :: [Adventurer.t()]
  defp reduce_adventurers(adventurers) do
    Enum.reduce(adventurers, [], fn a, acc ->
      adventurer = Map.put(a, :id, Ecto.UUID.generate())
      {:ok, adventurer} = get_or_add_adventurer(adventurer)
      [adventurer | acc]
    end)
  end

  @spec get_or_add_adventurer(adventurer_changeset :: Ecto.Changestet.t(Adventurer.t())) ::
          {:ok, Adventurer.t()} | {:error, :adventurer_not_found}
  defp get_or_add_adventurer(adventurer_changeset) do
    with {:ok, adventurer} <- Ecto.Changeset.apply_action(adventurer_changeset, :update) do
      server = lookup_adventurer_server(adventurer.id)

      case is_nil(adventurer.id) do
        true ->
          adventurer = Map.put(adventurer, :id, Ecto.UUID.generate())
          :ok = Agent.update(server, fn a -> a end)
          {:ok, adventurer}

        false ->
          {:ok, adventurer}
      end
    end
  end

  @spec lookup_adventurer_server(adventurer_id :: String.t() | nil) :: pid() | nil
  defp lookup_adventurer_server(adventurer_id) do
    case Registry.lookup(Infra.Adventurers.Registry, adventurer_id) do
      [{pid, _state}] ->
        pid

      _not_found ->
        nil
    end
  end

  @spec lookup_quest_server(quest_id :: String.t()) :: pid() | nil
  defp lookup_quest_server(quest_id) do
    case Registry.lookup(Infra.Quests.Registry, quest_id) do
      [{pid, _state}] ->
        pid

      _not_found ->
        nil
    end
  end
end
