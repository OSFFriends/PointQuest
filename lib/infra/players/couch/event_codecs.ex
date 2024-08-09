defimpl CouchDB.Document, for: PointQuest.Players.Event.GlyphCreated do
  def to_codec(%PointQuest.Players.Event.GlyphCreated{}), do: :ecto
end
