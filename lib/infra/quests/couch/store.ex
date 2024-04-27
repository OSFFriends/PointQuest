defmodule Infra.Quests.Couch.Store do
  @moduledoc """
  A store where you can buy and sell quests and quest accessories
  """
  use Projectionist.Store
  # alias Infra.Quests.QuestReader
  alias Infra.Quests.Couch.Reader, as: CouchReader

  def start_link(_opts) do
    Projectionist.Store.start_link(
      name: __MODULE__,
      projection: PointQuest.Quests.Quest,
      snapshot: nil,
      source: %CouchReader{}
    )
  end
end
