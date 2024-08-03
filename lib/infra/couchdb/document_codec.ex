defmodule CouchDB.DocumentCodec do
  @type t :: :ecto
  @type encodable :: map
  @type schema :: struct

  @callback from_doc(encodable, CouchDB.DocumentCodec.Metadata.t()) :: schema
  @callback to_doc(schema) :: encodable
  @callback to_metadata(schema) :: CouchDB.DocumentCodec.Metadata.t()
end
