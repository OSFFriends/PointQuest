defmodule PointQuest.Quests.Quest do
  @moduledoc """
  Object for holding the current voting context
  """

  @behaviour Projectionist.Projection

  use Ecto.Schema

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Attack
  alias PointQuest.Quests.Commands
  alias PointQuest.Quests.Event

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    embeds_many :adventurers, Adventurer
    embeds_many :attacks, Attack
    embeds_one :party_leader, Quests.PartyLeader
    field :name, :string
    field :all_adventurers_attacking?, :boolean
  end

  def init() do
    {:ok,
     %__MODULE__{
       adventurers: [],
       attacks: [],
       name: nil,
       all_adventurers_attacking?: nil
     }}
  end

  def project(%Event.QuestStarted{party_leaders_adventurer: nil} = event, quest) do
    party_leader =
      %Quests.PartyLeader{}
      |> Quests.PartyLeader.changeset(%{
        id: Nanoid.generate_non_secure(),
        quest_id: event.quest_id
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | id: event.quest_id,
        adventurers: [],
        party_leader: party_leader,
        name: event.name,
        all_adventurers_attacking?: false
    }
  end

  def project(%Event.QuestStarted{} = event, quest) do
    party_leaders_adventurer_params =
      event.party_leaders_adventurer
      |> Ecto.embedded_dump(:json)
      |> Map.put(:quest_id, event.quest_id)
      |> Map.put(:id, Nanoid.generate_non_secure())

    party_leader =
      %Quests.PartyLeader{}
      |> Quests.PartyLeader.changeset(%{
        id: Nanoid.generate_non_secure(),
        quest_id: event.quest_id,
        adventurer: party_leaders_adventurer_params
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | id: event.quest_id,
        adventurers: [],
        party_leader: party_leader,
        name: event.name,
        all_adventurers_attacking?: false
    }
  end

  def project(%Event.AdventurerJoinedParty{} = event, quest) do
    adventurer =
      %Quests.Adventurer{}
      |> Adventurer.create_changeset(%{
        id: event.id,
        name: event.name,
        class: event.class,
        quest_id: event.quest_id
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | adventurers: [adventurer | quest.adventurers],
        all_adventurers_attacking?: false
    }
  end

  def handle(%Commands.StartQuest{} = command, _quest) do
    {:ok, Event.QuestStarted.new!(Ecto.embedded_dump(command, :json))}
    # {:error, error}
  end

  def handle(%Commands.AddAdventurer{} = command, quest) do
    if Enum.any?(quest.adventurers, fn a -> a.name == command.name end) do
      {:error, :adventurer_already_present}
    else
      {:ok, Event.AdventurerJoinedParty.new!(Ecto.embedded_dump(command, :json))}
    end
  end
end
