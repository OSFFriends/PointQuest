defmodule PointQuest.Quests.Event.QuestStarted do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule PartyLeader do
    use Ecto.Schema
    import Ecto.Changeset

    alias PointQuest.Quests.Adventurer

    embedded_schema do
      field :name, :string
      field :class, Adventurer.ClassEnum
    end

    def changeset(party_leader, params \\ %{}) do
      party_leader
      |> cast(params, [:name, :class])
      |> validate_required([:name, :class])
    end
  end

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :name, :string
    field :lead_from_the_front, :boolean
    embeds_one :party_leader, PartyLeader
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:insert)
  end

  def changeset(quest_started, params \\ %{}) do
    quest_started
    |> change(quest_id: Nanoid.generate_non_secure(8))
    |> cast(params, [:quest_id, :name, :lead_from_the_front])
    |> cast_embed(:party_leader, required: true)
  end
end
