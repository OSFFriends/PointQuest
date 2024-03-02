defmodule PointQuest.Quests.Event.AdventurerJoinedParty do
  use Ecto.Schema
  import Ecto.Changeset
  alias PointQuest.Quests.Adventurer

  embedded_schema do
    field :quest_id
    field :name
    field :class, Adventurer.ClassEnum
  end

  def changeset(adventurer_joined, params \\ %{}) do
    adventurer_joined
    |> cast(params, [:quest_id, :name, :class])
    |> validate_required([:quest_id, :name])
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:insert)
  end
end
