defmodule CouchDB.DocumentCodec.Ecto do
  @behaviour CouchDB.DocumentCodec

  alias CouchDB.DocumentCodec

  @impl DocumentCodec
  def to_metadata(schema) do
    %DocumentCodec.Metadata{
      type: :ecto,
      properties: %{
        module: schema.__struct__
      }
    }
  end

  @impl DocumentCodec
  def to_doc(schema) do
    Ecto.embedded_dump(schema, :json)
  end

  @impl DocumentCodec
  def from_doc(encodable, %DocumentCodec.Metadata{type: :ecto, properties: %{"module" => module}}) do
    Ecto.embedded_load(String.to_existing_atom(module), encodable, :json)
  end
end
