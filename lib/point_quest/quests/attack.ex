defmodule PointQuest.Quests.Attack do
  @moduledoc """
  An attack an adventurer makes against the current ticket
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests

  @primary_key false
  embedded_schema do
    field :adventurer_id, :string
    field :attack, Quests.AttackValue
  end

  def create_changeset(attack, params \\ %{}) do
    attack
    |> cast(params, [:adventurer_id, :attack])
    |> validate_required([:adventurer_id, :attack])
  end
end
