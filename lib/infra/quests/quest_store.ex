defmodule Infra.Quests.QuestStore do
  @moduledoc """
  A store where you can buy and sell quests and quest accessories
  """
  use Projectionist.Store

  def start_link(_opts) do
    Projectionist.Store.start_link(
      name: __MODULE__,
      projection: PointQuest.Quests.Quest,
      snapshot: %Infra.Quests.Db{},
      source: Infra.SimpleReader.new()
    )
  end
end
