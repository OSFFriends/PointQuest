defmodule Infra.Quests.InMemory.Db do
  @moduledoc """
  In-memory DB system
  """
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias Infra.Quests.InMemory
  alias PointQuest.Error
  alias PointQuest.Quests.Event
  alias PointQuest.Quests.Quest

  defstruct []

  @impl PointQuest.Behaviour.Quests.Repo
  def write(_quest, %Event.QuestStarted{} = event) do
    {:ok, pid} =
      Horde.DynamicSupervisor.start_child(
        Infra.Quests.InMemory.QuestSupervisor,
        {InMemory.QuestServer, quest_id: event.quest_id}
      )

    _event = InMemory.QuestServer.add_event(pid, event)

    :ok
  end

  def write(quest, event) do
    InMemory.QuestServer.add_event({:via, Horde.Registry, {InMemory.Registry, quest.id}}, event)
    :ok
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        {:error, Error.NotFound.exception(resource: :quest)}

      pid ->
        quest =
          pid
          |> InMemory.QuestServer.get_events()
          |> Enum.reduce(InMemory.QuestServer.get_snapshot(pid), &Quest.project/2)

        {:ok, quest}
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_adventurer_by_id(quest_id, adventurer_id) do
    case get_quest_by_id(quest_id) do
      {:ok, %{party: %{party_leader: %{adventurer: %{id: ^adventurer_id} = adventurer}}}} ->
        {:ok, adventurer}

      {:ok, %{party: %{adventurers: adventurers}}} ->
        case Enum.find(adventurers, fn %{id: id} -> id == adventurer_id end) do
          nil -> {:error, Error.NotFound.exception(resource: :adventurer)}
          adventurer -> {:ok, adventurer}
        end

      {:error, %Error.NotFound{resource: :quest}} = error ->
        error
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_party_leader_by_id(quest_id, leader_id) do
    case get_quest_by_id(quest_id) do
      {:ok, %{party: %{party_leader: %{id: ^leader_id} = party_leader}}} ->
        {:ok, party_leader}

      {:error, %Error.NotFound{resource: :quest}} = error ->
        error
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_all_adventurers(quest_id) do
    case get_quest_by_id(quest_id) do
      {:ok, %{party: %{party_leader: %{adventurer: leader}, adventurers: adventurers}}} ->
        {:ok, [leader | adventurers]}

      {:ok, %{party: %{adventurers: adventurers}}} ->
        {:ok, adventurers}

      {:error, %Error.NotFound{resource: :quest}} = error ->
        error
    end
  end

  defp lookup_quest_server(quest_id) do
    case Horde.Registry.lookup(InMemory.Registry, quest_id) do
      [{pid, _state}] ->
        pid

      _not_found ->
        nil
    end
  end
end
