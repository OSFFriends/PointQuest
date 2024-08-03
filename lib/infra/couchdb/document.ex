defprotocol CouchDB.Document do
  @spec to_codec(CouchDB.DocumentCodec.schema()) :: CouchDB.DocumentCodec.t()
  def to_codec(schema)
end
