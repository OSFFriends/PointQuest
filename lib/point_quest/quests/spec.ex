defmodule PointQuest.Quests.Spec do
  @moduledoc """
  The specifications for determining and enforcing policies.

  These should be helper predicates that, given specific input, determine if the input
  meets the required criteria.

  For instance, given an actor and a quest, a spec of `is_in_quest?(actor, quest)` would
  return true when the quest_id of the actor matches the id of the quest, and false otherwise.

  A client utilizing these specs can then determine if the action is allowed or not based on
  the outcome of checking the spec.
  """
  alias PointQuest.Authentication.Actor
  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Quest

  @spec is_attacker?(attacker :: Adventurer.t(), actor :: Actor.t()) :: boolean
  @doc """
  Ensure the provided attacker id is the actor
  """
  def is_attacker?(_attacker, %Actor.PartyLeader{adventurer: nil}), do: false

  def is_attacker?(%Adventurer{id: attacker_id}, %Actor.PartyLeader{
        adventurer: %{id: attacker_id}
      }),
      do: true

  def is_attacker?(%Adventurer{id: _attacker_id}, %Actor.PartyLeader{
        adventurer: %{id: _other_adventurer}
      }),
      do: false

  def is_attacker?(%Adventurer{id: attacker_id}, %Actor.Adventurer{adventurer: %{id: attacker_id}}),
      do: true

  def is_attacker?(%Adventurer{id: _attacker_id}, %Actor.Adventurer{
        adventurer: %{id: _other_adventurer}
      }),
      do: false

  def is_attacker?(nil, _actor), do: false

  @spec is_in_party?(quest :: Quest.t(), actor :: Actor.t()) :: boolean
  @doc """
  Ensure the actor belongs to the provided party
  """
  def is_in_party?(%Quest{id: quest_id}, %Actor.PartyLeader{quest_id: quest_id}), do: true
  def is_in_party?(%Quest{id: _quest_id}, %Actor.PartyLeader{quest_id: _other_quest}), do: false

  def is_in_party?(%Quest{id: quest_id}, %Actor.Adventurer{quest_id: quest_id}), do: true
  def is_in_party?(%Quest{id: _quest_id}, %Actor.Adventurer{quest_id: _other_quest}), do: false

  @spec is_party_leader?(quest :: Quest.t(), actor :: Actor.t()) :: boolean
  @doc """
  Ensures the actor is the party leader of the provided quest
  """
  def is_party_leader?(%Quest{party_leader: %{id: id}}, %Actor.PartyLeader{leader_id: id}),
    do: true

  def is_party_leader?(%Quest{party_leader: %{id: _id}}, %Actor.PartyLeader{leader_id: _other_id}),
    do: false

  def is_party_leader?(_quest, %Actor.Adventurer{}), do: false
end
