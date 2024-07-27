defmodule PointQuest.Quests.Event.AdventurerAttacked do
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests.AttackValue

  embedded_schema do
    field :quest_id, :string
    field :adventurer_id, :string
    field :attack, AttackValue
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:insert)
  end

  def changeset(adventurer_attacked, params \\ %{}) do
    adventurer_attacked
    |> cast(params, [:quest_id, :adventurer_id, :attack])
    |> validate_required([:quest_id, :adventurer_id, :attack])
  end
end
