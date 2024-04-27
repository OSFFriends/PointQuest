defmodule Infra.Quests.SimpleInMemory.Db do
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias Infra.Quests.SimpleInMemory
  alias PointQuest.Error
  alias PointQuest.Quests.Event

  @impl PointQuest.Behaviour.Quests.Repo
  def write(_quest, %Event.QuestStarted{} = event) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        SimpleInMemory.QuestSupervisor,
        {SimpleInMemory.EventServer, quest_id: event.quest_id}
      )

    _event = SimpleInMemory.EventServer.add_event(pid, event)
    new_quest = SimpleInMemory.EventServer.get_quest(pid)

    {:ok, new_quest}
  end

  def write(quest, event) do
    event_store = {:via, Registry, {SimpleInMemory.Registry, quest.id}}

    SimpleInMemory.EventServer.add_event(
      event_store,
      event
    )

    new_quest = SimpleInMemory.EventServer.get_quest(event_store)

    {:ok, new_quest}
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case Registry.lookup(SimpleInMemory.Registry, quest_id) do
      [] ->
        {:error, Error.NotFound.exception(resource: :quest)}

      [{pid, _state}] ->
        {:ok, SimpleInMemory.EventServer.get_quest(pid)}
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
end
