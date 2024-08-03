defmodule CouchDB.Document do
  @moduledoc """
  Utilities for working with CouchDB documents.
  """
  alias PointQuest.Quests.Event

  @doc """
  Merges id and rev from `doc` into `struct`.

  When a new doc is created in couch the id and the rev come back in the response
  as `id` and `rev`. This function can be used to extract these values and merge
  into a model.
  """
  def merge_identifiers(struct, %{"id" => id, "rev" => rev}) do
    Map.merge(struct, %{id: id, rev: rev})
  end

  @doc """
  Convert `model` into format better persisted in couchdb.

  * Adds a `document_type` for the given model
  * Drops `id` and `rev` (stored in couch as `_rev`, `_id`)

  # TODO: tion` flag on update to have rev -> _rev
  """
  def to_doc(model) do
    model
    |> Ecto.embedded_dump(:json)
    |> Map.put(:document_type, document_type_for(model))
    |> Map.drop([:id, :rev])
  end

  @doc """
  Loads `model` from `doc`.
  """
  def from_doc(doc) do
    # move _rev and _id to rev and id
    {id, doc} = Map.pop(doc, "_id")
    {rev, doc} = Map.pop(doc, "_rev")
    doc = Map.merge(doc, %{"id" => id, "rev" => rev})

    doc["document_type"]
    |> type_from_document()
    |> Ecto.embedded_load(doc, :atoms)
  end

  defp document_type_for(%Event.QuestStarted{}), do: "quest_started"
  defp document_type_for(%Event.AdventurerJoinedParty{}), do: "adventurer_joined_party"
  defp document_type_for(%Event.AdventurerAttacked{}), do: "adventurer_attacked"
  defp document_type_for(%Event.AdventurerRemovedFromParty{}), do: "adventurer_removed"
  defp document_type_for(%Event.ObjectiveAdded{}), do: "objective_added"
  defp document_type_for(%Event.ObjectiveSorted{}), do: "objective_sorted"
  defp document_type_for(%Event.RoundStarted{}), do: "round_started"
  defp document_type_for(%Event.RoundEnded{}), do: "round_ended"

  defp type_from_document("quest_started"), do: Event.QuestStarted
  defp type_from_document("adventurer_joined_party"), do: Event.AdventurerJoinedParty
  defp type_from_document("adventurer_attacked"), do: Event.AdventurerAttacked
  defp type_from_document("adventurer_removed"), do: Event.AdventurerRemovedFromParty
  defp type_from_document("objective_added"), do: Event.ObjectiveAdded
  defp type_from_document("objective_sorted"), do: Event.ObjectiveSorted
  defp type_from_document("round_started"), do: Event.RoundStarted
  defp type_from_document("round_ended"), do: Event.RoundEnded
end
