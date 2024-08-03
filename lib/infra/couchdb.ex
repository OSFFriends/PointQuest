defmodule CouchDB do
  def get(url, opts \\ []) do
    CouchDB.Client.get(url, opts)
  end

  def put(url, doc, opts \\ [])

  def put(url, doc, opts) when is_struct(doc) do
    :ecto = CouchDB.Document.to_codec(doc)
    encoded = CouchDB.DocumentCodec.Ecto.to_doc(doc)
    metadata = CouchDB.DocumentCodec.Ecto.to_metadata(doc)
    CouchDB.Client.put(url, %{data: encoded, metadata: metadata}, opts)
  end

  def put(url, doc, opts) do
    CouchDB.Client.put(url, doc, opts)
  end

  def post(url, doc, opts \\ []) do
    CouchDB.Client.post(url, doc, opts)
  end

  def paginate_view(view, page_opts, opts \\ []) do
    view
    |> CouchDB.Client.paginate_view(page_opts, opts)
    |> Stream.map(fn
      %{
        "id" => id,
        "doc" => %{"data" => data, "metadata" => %{"type" => "ecto", "properties" => props}}
      } ->
        metadata = struct!(CouchDB.DocumentCodec.Metadata, %{type: :ecto, properties: props})
        CouchDB.DocumentCodec.Ecto.from_doc(Map.put(data, "id", id), metadata)

      no_metadata ->
        no_metadata
    end)
  end
end
