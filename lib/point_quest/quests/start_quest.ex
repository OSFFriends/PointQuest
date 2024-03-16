defmodule PointQuest.Quests.StartQuest do
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests

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
      |> cast(params, [:name, :class])
      |> Adventurer.Class.maybe_default_class()
      |> validate_required([:name])
    end
  end

  @primary_key false
  embedded_schema do
    field :name, :string
    embeds_one :party_leaders_adventurer, PartyLeadersAdventurer
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:insert)
  end

  defp changeset(start_quest, params) do
    start_quest
    |> cast(params, [:name])
    |> cast_embed(:party_leaders_adventurer)
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  def execute(%__MODULE__{} = start_quest_command) do
    # TODO: add telemetry events here
    with {:ok, event} <- Quests.Quest.handle(start_quest_command, %Quests.Quest{}) do
      repo().write(
        %Quests.Quest{},
        event
      )
    end
  end
end
