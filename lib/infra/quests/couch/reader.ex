defmodule Infra.Quests.Couch.Reader do
  defstruct []

  defimpl Projectionist.Reader do
    alias Infra.Couch
    alias Infra.Quests.Couch.Reader, as: CouchReader
    alias Projectionist.Reader

    def read(%CouchReader{}, %Reader.Read{position: :FIRST, id: _quest_id}) do
      []
    end

    def stream(
          %CouchReader{},
          %Reader.Read{position: :FIRST, id: quest_id},
          callback
        ) do
      with {:ok, %{"rows" => docs}} <-
             Couch.Client.get(
               "/events/_partition/quest-#{quest_id}/_all_docs?include_docs=true&sorted=true"
             ) do
        docs
        |> Enum.map(&Couch.Document.from_doc(&1["doc"]))
        |> then(callback)
      end
    end
  end
end
