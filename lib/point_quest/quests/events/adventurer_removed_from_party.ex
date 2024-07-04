defmodule PointQuest.Quests.Event.AdventurerRemovedFromParty do
  use PointQuest.Valuable

  @primary_key false
  embedded_schema do
    field :quest_id
    field :adventurer_id
  end

  def changeset(adventurer_removed, params \\ %{}) do
    adventurer_removed
    |> cast(params, [:quest_id, :adventurer_id])
    |> validate_required([:quest_id, :adventurer_id])
  end
end
