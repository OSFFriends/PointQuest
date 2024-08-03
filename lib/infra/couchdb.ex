defmodule CouchDB do
  def get(url, opts \\ []) do
    CouchDB.Client.get(url, opts)
  end

  def put(url, doc, opts \\ []) do
    CouchDB.Client.put(url, doc, opts)
  end

  def post(url, doc, opts \\ []) do
    CouchDB.Client.post(url, doc, opts)
  end

  def paginate_view(view, page_opts, opts \\ []) do
    view
    |> CouchDB.Client.paginate_view(page_opts, opts)
    |> Stream.map(&CouchDB.Document.from_doc(&1["doc"]))
  end
end
