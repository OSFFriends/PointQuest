defmodule Infra.Players.Couch.Db do
  @behaviour PointQuest.Behaviour.Players.Repo

  alias PointQuest.Players

  @impl PointQuest.Behaviour.Players.Repo
  def write(%Players.Character{} = _init_character, %Players.Event.CharacterCreated{} = event) do
    with {:ok, doc} <-
           CouchDB.Client.put(
             "/players-v1/character-#{event.character_id}:#{ExULID.ULID.generate()}",
             event
           ) do
      {:ok, Map.put(event, :id, doc["id"])}
    end
  end

  @impl PointQuest.Behaviour.Players.Repo
  def write(%Players.Glyph{} = _init_glyph, %Players.Event.GlyphCreated{} = event) do
    with {:ok, doc} <-
           CouchDB.Client.put(
             "/players-v1/glyph-#{event.guild}-#{event.guild_id}:#{ExULID.ULID.generate()}",
             event
           ) do
      {:ok, Map.put(event, :id, doc["id"])}
    end
  end

  @impl PointQuest.Behaviour.Players.Repo
  def get_glyph_by_guild({guild, id}) do
    init_glyph = Players.Glyph.init()

    "/players-v1/_partition/glyph-#{guild}-#{id}/_all_docs"
    |> CouchDB.paginate_view(%{start_key: [guild, id]})
    |> Enum.reduce(init_glyph, &Players.Glyph.project/2)
    |> case do
      ^init_glyph ->
        {:error, PointQuest.Error.NotFound.exception(resource: :glyph)}

      glyph ->
        {:ok, glyph}
    end
  end
end
