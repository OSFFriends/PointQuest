defmodule Infra.Quests.Couch.Db do
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias PointQuest.Error
  alias PointQuest.Quests.Event

  alias Infra.Couch
  alias Infra.Quests.Couch, as: QuestCouch

  @impl PointQuest.Behaviour.Quests.Repo
  def write(_init_quest, %Event.QuestStarted{} = event) do
    with {:ok, doc} <-
           Couch.Client.put(
             "/events-v2/quest-#{event.quest_id}:#{ExULID.ULID.generate()}",
             Couch.Document.to_doc(event)
           ),
         {:ok, pid} <-
           Horde.DynamicSupervisor.start_child(
             QuestCouch.QuestSupervisor,
             {QuestCouch.QuestServer, quest_id: event.quest_id}
           ) do
      QuestCouch.QuestServer.get(pid)
      {:ok, Map.put(event, :id, doc["id"])}
    end
  end

  def write(quest, event) do
    quest.id
    |> lookup_quest_server()
    |> QuestCouch.QuestServer.add_event(event)
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        case Horde.DynamicSupervisor.start_child(
               QuestCouch.QuestSupervisor,
               {QuestCouch.QuestServer, quest_id: quest_id}
             ) do
          {:error, %PointQuest.Error.NotFound{}} = not_found ->
            not_found

          {:ok, pid} ->
            {:ok, QuestCouch.QuestServer.get(pid)}
        end

      pid ->
        {:ok, QuestCouch.QuestServer.get(pid)}
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
    case Horde.Registry.lookup(Infra.Quests.Couch.Registry, quest_id) do
      [{pid, _state}] ->
        pid

      _not_found ->
        nil
    end
  end
end
