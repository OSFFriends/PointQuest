defmodule PointQuest.Quests.Event.QuestStarted do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule PartyLeadersAdventurer do
    @moduledoc """
    The adventurer that participates in the quest
    """
    use Ecto.Schema

    import Ecto.Changeset

    alias PointQuest.Quests.Adventurer

    @type t :: %__MODULE__{
            name: String.t(),
            class: Adventurer.Class.NameEnum.t()
          }

    @primary_key {:id, :binary_id, autogenerate: true}
    embedded_schema do
      field :name, :string
      field :class, Adventurer.Class.NameEnum
    end

    def changeset(adventurer, params \\ %{}) do
      adventurer
      |> cast(params, [:id, :name, :class])
      |> validate_required([:id, :name])
    end
  end

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :name, :string
    field :leader_id, :string
    embeds_one :party_leaders_adventurer, PartyLeadersAdventurer
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:insert)
  end

  def changeset(quest_started, params \\ %{}) do
    quest_started
    |> cast(params, [:quest_id, :name, :leader_id])
    |> validate_required([:quest_id, :name, :leader_id])
    |> cast_embed(:party_leaders_adventurer)
  end
end
