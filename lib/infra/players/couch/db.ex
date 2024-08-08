defmodule Infra.Players.Couch.Db do
  @behaviour PointQuest.Behaviour.Players.CharacterRepo

  alias PointQuest.Players

  @impl PointQuest.Behaviour.Players.CharacterRepo
  def write(_init_character, %Players.Event.CharacterCreated{} = event) do
    with {:ok, doc} <-
           CouchDB.Client.put(
             "/characters-v1/character-#{event.character_id}:#{ExULID.ULID.generate()}",
             event
           ) do
      {:ok, Map.put(event, :id, doc["id"])}
    end
  end
end
