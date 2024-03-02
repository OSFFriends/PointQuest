defmodule PointQuest.Quests.StartQuest do
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests

  # duplicating this intentionally to allow drift between
  # event and command
  defmodule PartyLeader do
    use Ecto.Schema
    import Ecto.Changeset

    alias PointQuest.Quests.Adventurer

    @primary_key false
    embedded_schema do
      field :name, :string
      field :class, Adventurer.ClassEnum
    end

    def changeset(party_leader, params \\ %{}) do
      party_leader
      |> cast(params, [:name, :class])
      |> validate_required([:name])
    end
  end

  @primary_key false
  embedded_schema do
    field :name, :string
    field :lead_from_the_front, :boolean
    embeds_one :party_leader, PartyLeader
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
    |> cast(params, [:name, :lead_from_the_front])
    |> cast_embed(:party_leader, required: true)
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
