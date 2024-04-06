defmodule Infra.Quests.Db do
  @moduledoc """
  In-memory DB system
  """
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias Infra.Quests.QuestServer
  alias PointQuest.Error
  alias PointQuest.Quests.Event

  defstruct []

  @impl PointQuest.Behaviour.Quests.Repo
  def write(quest, %Event.QuestStarted{} = event) do
    {:ok, pid} =
      DynamicSupervisor.start_child(Infra.Quests.QuestSupervisor, {QuestServer, quest: quest})

    _event = QuestServer.add_event(pid, event)
    new_quest = Projectionist.Store.get(Infra.Quests.QuestStore, quest.id)

    {:ok, new_quest}
  end

  def write(quest, event) do
    QuestServer.add_event({:via, Registry, {Infra.Quests.Registry, quest.id}}, event)
    {:ok, Projectionist.Store.get(Infra.Quests.QuestStore, quest.id)}
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        {:error, Error.NotFound.exception(resource: :quest)}

      _pid ->
        {:ok, Projectionist.Store.get(Infra.Quests.QuestStore, quest_id)}
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_adventurer_by_id(quest_id, adventurer_id) do
    case get_quest_by_id(quest_id) do
      {:ok, %{party_leader: %{adventurer: %{id: ^adventurer_id} = adventurer}}} ->
        {:ok, adventurer}

      {:ok, %{adventurers: adventurers}} ->
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
      {:ok, %{party_leader: %{id: ^leader_id} = party_leader}} ->
        {:ok, party_leader}

      {:error, %Error.NotFound{resource: :quest}} = error ->
        error
    end
  end

  def get_all_adventurers(quest_id) do
    case get_quest_by_id(quest_id) do
      {:ok, %{party_leader: %{adventurer: leader}, adventurers: adventurers}} ->
        {:ok, [leader | adventurers]}

      {:ok, %{adventurers: adventurers}} ->
        {:ok, adventurers}

      {:error, %Error.NotFound{resource: :quest}} = error ->
        error
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
