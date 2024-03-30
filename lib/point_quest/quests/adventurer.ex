defmodule PointQuest.Quests.Adventurer do
  @moduledoc """
  The adventurer that participates in the quest
  """
  use Ecto.Schema

  import Ecto.Changeset
  import PointQuest.Macros.Enum

  @type t :: %__MODULE__{
          name: String.t(),
          class: Adventurer.Class.NameEnum.t(),
          quest_id: String.t()
        }

  defmodule Class do
    @moduledoc """
    The class that an adventurer has
    """
    defenum NameEnum, :class, [:healer, :mage, :knight]

    def maybe_default_class(adventurer_changeset) do
      case get_field(adventurer_changeset, :class) do
        nil ->
          change(adventurer_changeset, class: Enum.random([:healer, :mage, :knight]))

        _class ->
          adventurer_changeset
      end
    end
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :class, Class.NameEnum
    field :quest_id, :string
  end

  def create_changeset(adventurer, params \\ %{}) do
    adventurer
    |> cast(params, [:id, :name, :class, :quest_id])
    |> Class.maybe_default_class()
    |> validate_required([:name, :class, :quest_id])
  end
end
