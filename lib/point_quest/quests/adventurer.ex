defmodule PointQuest.Quests.Adventurer do
  @moduledoc """
  The adventurer that participates in the quest
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
  end

  def create_changeset(adventurer, params \\ %{}) do
    adventurer
    |> cast(params, [:id, :name])
    |> validate_required([:name])
  end
end
