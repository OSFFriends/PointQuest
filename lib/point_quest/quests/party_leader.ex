defmodule PointQuest.Quests.PartyLeader do
  @moduledoc """
  The leader of the party, who may or may not be an adventurer also.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias PointQuest.Quests.Adventurer

  @type t :: %__MODULE__{
          quest_id: String.t(),
          adventurer: Adventurer.t() | nil
        }

  embedded_schema do
    field :quest_id, :string
    embeds_one :adventurer, Adventurer
  end

  def changeset(party_leader, params \\ %{}) do
    party_leader
    |> cast(params, [:id, :quest_id])
    |> validate_required([:quest_id])
    |> cast_embed(:adventurer, with: &Adventurer.create_changeset/2)
  end
end
