defmodule Infra.Quests.Couch.Db do
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias PointQuest.Error
  alias PointQuest.Quests.Quest
  alias PointQuest.Quests.Event

  alias Infra.Couch

  @impl PointQuest.Behaviour.Quests.Repo
  def write(_init_quest, %Event.QuestStarted{} = event) do
    {:ok, _doc} =
      Couch.Client.put(
        "/events/quest-#{event.quest_id}:#{ExULID.ULID.generate()}",
        Couch.Document.to_doc(event)
      )

    :ok
  end

  def write(quest, event) do
    {:ok, _doc} =
      Couch.Client.put(
        "/events/quest-#{quest.id}:#{ExULID.ULID.generate()}",
        Couch.Document.to_doc(event)
      )

    :ok
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    with {:ok, %{"rows" => [snapshot]}} <-
           Couch.Client.get("/quest-snapshots/_partition/quest-#{quest_id}/_all_docs",
             query: [limit: 1, sorted: true, descending: true]
           ) do
      quest_snapshot = Couch.Document.from_doc(snapshot["doc"])

      "/events/_partition/quest-#{quest_id}/_all_docs"
      |> Couch.Client.paginate_view(%{
        starting_key: snapshot["id"] <> Couch.Client.last_string_char()
      })
      |> Enum.reduce(quest_snapshot, &Quest.project/2)
      |> case do
        %{id: nil} ->
          {:error, Error.NotFound.exception(reource: :quest)}

        quest ->
          {:ok, quest}
      end
    else
      {:ok, %{"rows" => []}} ->
        init_quest = Quest.init()

        "/events/_partition/quest-#{quest_id}/_all_docs"
        |> Couch.Client.paginate_view(%{})
        |> Enum.reduce(init_quest, &Quest.project/2)
        |> case do
          %{id: nil} ->
            {:error, Error.NotFound.exception(reource: :quest)}

          quest ->
            {:ok, quest}
        end
    end

    # "/events/_partition/quest-#{quest_id}/_all_docs"
    # |> Couch.Client.paginate_view(%{})
    # |> Enum.reduce(init_quest, &Quest.project/2)
    # |> case do
    #   %{id: nil} ->
    #     {:error, Error.NotFound.exception(reource: :quest)}
    #
    #   quest ->
    #     {:ok, quest}
    # end
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
