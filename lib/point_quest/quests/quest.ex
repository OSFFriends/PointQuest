defmodule PointQuest.Quests.Quest do
  @moduledoc """
  Object for holding the current voting context
  """

  use Ecto.Schema

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Attack
  alias PointQuest.Quests.Commands
  alias PointQuest.Quests.Event
  alias PointQuest.Quests.Objectives.Objective
  alias PointQuest.Quests.Objectives.Questable
  alias PointQuest.Quests.Party

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    embeds_many :attacks, Attack
    embeds_many :objectives, Objective
    embeds_one :party, Party
    field :round_active?, :boolean
    field :quest_objective, :string
  end

  def init() do
    %__MODULE__{
      id: nil,
      party: nil,
      attacks: [],
      round_active?: false,
      quest_objective: ""
    }
  end

  def project(%Event.QuestStarted{party_leaders_adventurer: nil} = event, quest) do
    party =
      %Party{}
      |> Party.changeset(%{
        party_leader: %{
          id: event.leader_id,
          quest_id: event.quest_id
        }
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | id: event.quest_id,
        party: party
    }
  end

  def project(%Event.QuestStarted{} = event, quest) do
    party_leaders_adventurer_params =
      event.party_leaders_adventurer
      |> Ecto.embedded_dump(:json)
      |> Map.put(:quest_id, event.quest_id)
      |> Map.put(:id, event.leader_id)

    party =
      %Party{}
      |> Party.changeset(%{
        party_leader: %{
          id: event.leader_id,
          quest_id: event.quest_id,
          adventurer: party_leaders_adventurer_params
        }
      })
      |> Ecto.Changeset.apply_action!(:insert)

    %__MODULE__{
      quest
      | id: event.quest_id,
        party: party,
        round_active?: false
    }
  end

  def project(%Event.AdventurerJoinedParty{} = event, quest) do
    adventurer =
      %Quests.Adventurer{}
      |> Adventurer.create_changeset(%{
        id: event.adventurer_id,
        name: event.name,
        class: event.class,
        quest_id: event.quest_id
      })
      |> Ecto.Changeset.apply_action!(:insert)

    party =
      %Party{
        quest.party
        | adventurers: [adventurer | quest.party.adventurers]
      }

    %__MODULE__{
      quest
      | party: party
    }
  end

  def project(%Event.AdventurerAttacked{} = command, %__MODULE__{attacks: attacks} = quest) do
    # adventurer could be updating their previous attack
    updated_attacks =
      [struct(Attack, Map.take(command, [:adventurer_id, :attack])) | attacks]
      |> Enum.uniq_by(fn %{adventurer_id: id} -> id end)

    %__MODULE__{
      quest
      | attacks: updated_attacks
    }
  end

  def project(%Event.RoundStarted{objectives: objectives}, %__MODULE__{} = quest) do
    %__MODULE__{
      quest
      | round_active?: true,
        attacks: [],
        objectives: objectives
    }
  end

  def project(%Event.RoundEnded{objectives: objectives}, %__MODULE__{} = quest) do
    %__MODULE__{
      quest
      | round_active?: false,
        objectives: objectives
    }
  end

  def project(
        %Event.ObjectiveAdded{objectives: objectives},
        %__MODULE__{} = quest
      ) do
    %__MODULE__{
      quest
      | objectives: objectives
    }
  end

  def project(
        %Event.ObjectiveSorted{objectives: objectives},
        %__MODULE__{} = quest
      ) do
    %__MODULE__{
      quest
      | objectives: objectives
    }
  end

  def handle(%Commands.StartQuest{party_leaders_adventurer: nil} = command, _quest) do
    event =
      command
      |> Ecto.embedded_dump(:json)
      |> Map.merge(%{leader_id: Nanoid.generate_non_secure()})
      |> Event.QuestStarted.new!()

    {:ok, event}
  end

  def handle(%Commands.StartQuest{} = command, _quest) do
    leader_id = Nanoid.generate_non_secure()

    event =
      command
      |> Ecto.embedded_dump(:json)
      |> Map.merge(%{leader_id: leader_id})
      |> update_in([:party_leaders_adventurer, :id], fn _ -> leader_id end)
      |> Event.QuestStarted.new!()

    {:ok, event}
  end

  def handle(%Commands.AddAdventurer{} = command, quest) do
    if Enum.any?(quest.party.adventurers, fn a -> a.name == command.name end) do
      {:error, :adventurer_already_present}
    else
      {:ok, Event.AdventurerJoinedParty.new!(Ecto.embedded_dump(command, :json))}
    end
  end

  def handle(%Commands.Attack{} = command, _quest) do
    {:ok, Event.AdventurerAttacked.new!(Ecto.embedded_dump(command, :json))}
  end

  def handle(%Commands.StartRound{}, %{round_active?: true}), do: {:error, :round_already_active}

  def handle(%Commands.StartRound{} = command, quest) do
    objectives =
      case Enum.find(quest.objectives, fn o -> o.status == :incomplete end) do
        nil ->
          Enum.map(quest.objectives, fn o -> Ecto.embedded_dump(o, :json) end)

        first ->
          Enum.map(quest.objectives, fn o ->
            if o.id == first.id do
              %{o | status: :current} |> Ecto.embedded_dump(:json)
            else
              Ecto.embedded_dump(o, :json)
            end
          end)
      end

    {:ok,
     Event.RoundStarted.new!(%{
       quest_id: command.quest_id,
       objectives: objectives
     })}
  end

  def handle(%Commands.StopRound{} = _command, %{round_active?: false}),
    do: {:error, :round_not_active}

  def handle(%Commands.StopRound{} = command, quest) do
    objectives =
      case Enum.find(quest.objectives, fn o -> o.status == :current end) do
        nil ->
          Enum.map(quest.objectives, fn o -> Ecto.embedded_dump(o, :json) end)

        current ->
          Enum.map(quest.objectives, fn o ->
            if o.id == current.id do
              %{o | status: :complete} |> Ecto.embedded_dump(:json)
            else
              Ecto.embedded_dump(o, :json)
            end
          end)
      end

    {:ok, Event.RoundEnded.new!(%{quest_id: command.quest_id, objectives: objectives})}
  end

  def handle(%Commands.AddSimpleObjective{} = command, quest) do
    end_sort_value =
      Enum.max_by(quest.objectives, fn o -> o.sort_order end, fn -> %{sort_order: 0} end).sort_order

    new_objective =
      Questable.to_objective(command, %{sort_order: end_sort_value + 1})
      |> Ecto.embedded_dump(:json)

    objectives =
      [
        new_objective | Enum.map(quest.objectives, fn o -> Ecto.embedded_dump(o, :json) end)
      ]
      |> Enum.sort_by(fn o -> o.sort_order end)

    {:ok, Event.ObjectiveAdded.new!(%{quest_id: command.quest_id, objectives: objectives})}
  end

  def handle(%Commands.SortObjective{} = command, quest) do
    objectives =
      quest.objectives
      |> Enum.reduce([], fn o, acc ->
        if o.id == command.objective_id do
          [%{o | sort_order: command.sort_order} | acc]
        else
          [o | acc]
        end
      end)
      |> Enum.sort_by(& &1.sort_order)
      |> Enum.map(fn o -> Ecto.embedded_dump(o, :json) end)

    {:ok,
     Event.ObjectiveSorted.new!(%{
       quest_id: command.quest_id,
       objectives: objectives
     })}
  end
end
