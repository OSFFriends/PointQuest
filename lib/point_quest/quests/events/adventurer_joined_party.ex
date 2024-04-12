defmodule PointQuest.Quests.Event.AdventurerJoinedParty do
  use PointQuest.Valuable
  alias PointQuest.Quests.Adventurer

  embedded_schema do
    field :quest_id
    field :name
    field :class, Adventurer.Class.NameEnum
  end

  def changeset(adventurer_joined, params \\ %{}) do
    adventurer_joined
    |> cast(params, [:quest_id, :name, :class])
    |> change(id: Nanoid.generate_non_secure())
    |> validate_required([:quest_id, :name])
  end
end
