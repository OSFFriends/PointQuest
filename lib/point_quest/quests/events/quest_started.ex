defmodule PointQuest.Quests.Event.QuestStarted do
  use PointQuest.Valuable, optional_fields: [:party_leaders_adventurer]

  defmodule PartyLeadersAdventurer do
    @moduledoc """
    The adventurer that participates in the quest
    """
    use PointQuest.Valuable, optional_fields: [:class]

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
  end

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :name, :string
    field :leader_id, :string
    embeds_one :party_leaders_adventurer, PartyLeadersAdventurer
  end
end
