defmodule Infra.Quests.Couch.QuestSnapshots do
  @moduledoc """
  Retrieve and Store Quest Snapshots.
  """
  alias Infra.Couch.Client, as: CouchDB
  alias PointQuest.Quests.Quest

  @type version :: String.t()
  @type snapshot :: %{version: version(), snapshot: Quest.t()}

  @spec get_snapshot(quest_id :: String.t()) :: snapshot() | nil
  @doc """
  Retrieve quest snapshot at latest position or before a specified version.
  """
  def get_snapshot(quest_id, version \\ :latest)

  @spec get_snapshot(quest_id :: String.t(), :latest | {:before, version()}) :: snapshot() | nil
  def get_snapshot(quest_id, :latest) do
    "/quest-snapshots-v1/_partition/quest-#{quest_id}/_all_docs"
    |> CouchDB.get(query: [limit: 1, sorted: true, descending: true, include_docs: true])
    |> case do
      {:ok, %{"rows" => [snapshot]}} ->
        %{
          version: snapshot["id"],
          snapshot: Ecto.embedded_load(Quest, snapshot["doc"]["snapshot"], :json)
        }

      {:ok, %{"rows" => []}} ->
        nil
    end
  end

  def get_snapshot(quest_id, {:before, version}) do
    "/quest-snapshots-v1/_partition/quest-#{quest_id}/_all_docs"
    |> CouchDB.post(%{
      limit: 2,
      sorted: true,
      descending: true,
      include_docs: true,
      inclusive_end: false,
      start_key: version
    })
    |> case do
      {:ok, %{"rows" => [%{"id" => ^version}]}} ->
        nil

      {:ok, %{"rows" => [snapshot]}} ->
        %{
          version: snapshot["id"],
          snapshot: Ecto.embedded_load(Quest, snapshot["doc"]["snapshot"], :json)
        }

      {:ok, %{"rows" => [%{"id" => ^version}, snapshot]}} ->
        %{
          version: snapshot["id"],
          snapshot: Ecto.embedded_load(Quest, snapshot["doc"]["snapshot"], :json)
        }

      {:ok, %{"rows" => [snapshot | _tail]}} ->
        %{
          version: snapshot["id"],
          snapshot: Ecto.embedded_load(Quest, snapshot["doc"]["snapshot"], :json)
        }

      {:ok, %{"rows" => _rows}} ->
        nil
    end
  end

  @spec write_snapshot(snapshot()) :: :ok
  @doc """
  Write a new quest snapshot at version
  """
  def write_snapshot(%{version: version, snapshot: %Quest{} = quest}) do
    quest_data = Ecto.embedded_dump(quest, :json)

    {:ok, _doc} =
      CouchDB.put("/quest-snapshots-v1/#{version}", %{snapshot: quest_data})

    :ok
  end
end
