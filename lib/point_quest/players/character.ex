defmodule PointQuest.Players.Character do
  use Ecto.Schema
  import PointQuest.Macros.Enum
  alias PointQuest.Players

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          player_id: String.t(),
          class: ClassEnum.t()
        }

  defenum ClassEnum, :class, [:healer, :mage, :knight]

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :player_id, :string
    field :class, ClassEnum
  end

  def init() do
    %__MODULE__{}
  end

  def project(%Players.Event.CharacterCreated{} = character_created, _character) do
    params = Map.take(character_created, [:id, :name, :player_id, :class])

    Players.Event.CharacterCreated.new!(params)
  end

  def handle(%Players.Commands.CreateCharacter{} = create_character, _character) do
    params =
      create_character
      |> Map.take([:id, :name, :player_id, :class])
      |> Map.put_new(:character_id, ExULID.ULID.generate())

    {:ok, Players.Event.CharacterCreated.new!(params)}
  end
end
