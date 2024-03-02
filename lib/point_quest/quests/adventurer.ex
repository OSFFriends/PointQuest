defmodule PointQuest.Quests.Adventurer do
  @moduledoc """
  The adventurer that participates in the quest
  """
  use Ecto.Schema

  import Ecto.Changeset
  import EctoEnum

  @type t :: %__MODULE__{
          name: String.t(),
          class: ClassEnum.t()
        }

  defenum ClassEnum, healer: "healer", mage: "mage", knight: "knight"

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :class, ClassEnum
  end

  def create_changeset(adventurer, params \\ %{}) do
    adventurer
    |> cast(params, [:name, :class])
    |> maybe_default_class()
    |> validate_required([:name, :class])
  end

  defp maybe_default_class(adventurer_changeset) do
    case get_field(adventurer_changeset, :class) do
      nil ->
        change(adventurer_changeset, class: Enum.random([:healer, :mage, :knight]))

      _class ->
        adventurer_changeset
    end
  end
end
