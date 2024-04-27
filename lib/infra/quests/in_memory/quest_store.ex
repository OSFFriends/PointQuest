defmodule Infra.Quests.InMemory.QuestStore do
  @moduledoc """
  A store where you can buy and sell quests and quest accessories
  """
  use Projectionist.Store
  alias Infra.Quests.InMemory.QuestReader

  def start_link(_opts) do
    Projectionist.Store.start_link(
      name: __MODULE__,
      projection: PointQuest.Quests.Quest,
      snapshot: QuestReader.new(snapshot?: true),
      source: QuestReader.new(snapshot?: false)
    )
  end
end
