defmodule PointQuest.Authentication.Actor do
  @moduledoc """
  The entity performing actions against our app.
  """

  defmodule Adventurer do
    @moduledoc """
    A user that belongs to a party
    """
    use Ecto.Schema

    alias PointQuest.Quests

    @type t :: %__MODULE__{
            quest_id: String.t(),
            adventurer: Quests.Adventurer.t()
          }

    @primary_key false
    embedded_schema do
      field :quest_id, :string
      embeds_one :adventurer, Quests.Adventurer
    end
  end

  defmodule PartyLeader do
    @moduledoc """
    A leader that is leading the party
    """
    use Ecto.Schema

    alias PointQuest.Quests

    @type t :: %__MODULE__{
            quest_id: String.t(),
            leader_id: String.t(),
            adventurer: Quests.Adventurer.t() | nil
          }

    @primary_key false
    embedded_schema do
      field :quest_id, :string
      field :leader_id, :string
      embeds_one :adventurer, Quests.Adventurer
    end
  end

  @type t :: Adventurer.t() | PartyLeader.t()
end
