defmodule QuestSetupHelper do
  @moduledoc """
  A simple helper for tests requiring quest setup.
  """
  alias PointQuest.Quests.Commands.AddAdventurer
  alias PointQuest.Quests.Commands.GetAdventurer
  alias PointQuest.Quests.Commands.StartQuest

  def setup() do
    {:ok, quest_started} =
      StartQuest.new!(%{})
      |> StartQuest.execute()

    {:ok, %{party: %{party_leader: party_leader}} = quest} =
      PointQuest.quest_repo().get_quest_by_id(quest_started.quest_id)

    {:ok, quest_started} =
      StartQuest.new!(%{
        party_leaders_adventurer: %{name: "Stevey Beevey", class: :mage}
      })
      |> StartQuest.execute()

    {:ok, other_quest} = PointQuest.quest_repo().get_quest_by_id(quest_started.quest_id)

    {:ok, %{adventurer_id: adventurer_id}} =
      AddAdventurer.new!(%{name: "Sir Stephen Bolton", class: :knight, quest_id: quest.id})
      |> AddAdventurer.execute()

    {:ok, adventurer} =
      GetAdventurer.new!(%{quest_id: quest.id, adventurer_id: adventurer_id})
      |> GetAdventurer.execute()

    party_leader_actor = %PointQuest.Authentication.Actor.PartyLeader{
      quest_id: quest.id,
      leader_id: party_leader.id,
      adventurer: nil
    }

    adventurer_actor = %PointQuest.Authentication.Actor.Adventurer{
      quest_id: quest.id,
      adventurer: adventurer
    }

    other_actor = %PointQuest.Authentication.Actor.PartyLeader{
      quest_id: other_quest.id,
      leader_id: other_quest.party.party_leader.id,
      adventurer: other_quest.party.party_leader.adventurer
    }

    %{
      quest: quest,
      other_quest: other_quest,
      party_leader: party_leader,
      adventurer: adventurer,
      party_leader_actor: party_leader_actor,
      adventurer_actor: adventurer_actor,
      other_actor: other_actor
    }
  end
end
