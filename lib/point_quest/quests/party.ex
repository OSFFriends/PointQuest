defmodule PointQuest.Quests.Party do
  @moduledoc """
  Object for handling the party state.
  """
  use PointQuest.Valuable, optional_fields: [:adventurers]
  use Ecto.Schema

  alias PointQuest.Quests

  @type t :: %__MODULE__{
          adventurers: [Quests.Adventurer.t()],
          party_leader: Quests.PartyLeader.t()
        }

  @primary_key false
  embedded_schema do
    embeds_many :adventurers, Quests.Adventurer
    embeds_one :party_leader, Quests.PartyLeader
  end
end
