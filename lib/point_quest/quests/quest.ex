defmodule PointQuest.Quests.Quest do
  @moduledoc """
  Object for holding the current voting context
  """

  @behaviour Projectionist.Projection

  use Ecto.Schema

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Attack
  alias PointQuest.Quests.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    embeds_many :adventurers, Adventurer
    embeds_many :attacks, Attack
    embeds_one :party_leader, Adventurer
    field :name, :string
    field :lead_from_the_front, :boolean
    field :all_adventurers_attacking?, :boolean
  end

  def init() do
    {:ok,
     %__MODULE__{
       adventurers: [],
       attacks: [],
       party_leader: nil,
       name: nil,
       lead_from_the_front: nil,
       all_adventurers_attacking?: nil
     }}
  end

  def project(%Event.QuestStarted{} = event, quest) do
    party_leader =
      %Adventurer{}
      |> Adventurer.create_changeset(Ecto.embedded_dump(event.party_leader, :json))
      |> Ecto.Changeset.apply_action!(:insert)

    adventurers =
      if event.lead_from_the_front do
        [party_leader]
      else
        []
      end

    %__MODULE__{
      quest
      | id: event.quest_id,
        adventurers: adventurers,
        party_leader: party_leader,
        name: event.name,
        lead_from_the_front: event.lead_from_the_front,
        all_adventurers_attacking?: false
    }
  end

  def project(%Event.AdventurerJoinedParty{} = event, quest) do
    adventurer =
      %Adventurer{}
      |> Adventurer.create_changeset(%{name: event.name, class: event.class})
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | adventurers: [adventurer | quest.adventurers],
        all_adventurers_attacking?: false
    }
  end

  def handle(%Quests.StartQuest{} = command, _quest) do
    {:ok, Event.QuestStarted.new!(Ecto.embedded_dump(command, :json))}
    # {:error, error}
  end

  def handle(%Quests.AddAdventurer{} = command, quest) do
    if Enum.any?(quest.adventurers, fn a -> a.name == command.name end) do
      {:error, :adventurer_already_present}
    else
      {:ok, Event.AdventurerJoinedParty.new!(Ecto.embedded_dump(command, :json))}
    end
  end
end
