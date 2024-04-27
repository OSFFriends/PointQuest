defmodule Infra.Quests.Couch.Db do
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias PointQuest.Error
  alias PointQuest.Quests.Event

  alias Infra.Couch

  @impl PointQuest.Behaviour.Quests.Repo
  def write(_init_quest, %Event.QuestStarted{} = event) do
    Couch.Client.put(
      "/events/quest-#{event.quest_id}:#{ExULID.ULID.generate()}",
      Couch.Document.to_doc(event)
    )
    |> case do
      {:ok, _body} ->
        get_quest_by_id(event.quest_id)
    end
  end

  def write(quest, event) do
    Couch.Client.put(
      "/events/quest-#{quest.id}:#{ExULID.ULID.generate()}",
      Couch.Document.to_doc(event)
    )
    |> case do
      {:ok, _body} ->
        get_quest_by_id(quest.id)
    end
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case Projectionist.Store.get(Infra.Quests.Couch.Store, quest_id) do
      %{id: nil} ->
        {:error, Error.NotFound.exception(reource: :quest)}

      quest ->
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
end
