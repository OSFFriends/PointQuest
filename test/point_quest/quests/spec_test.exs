defmodule PointQuest.Quests.SpecTest do
  use ExUnit.Case

  alias PointQuest.Quests.Spec

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  describe "is_attacker?/2" do
    test "policy check succeeds if actor is the attacking adventurer", %{
      adventurer_actor: adventurer,
      other_actor: party_leader
    } do
      assert Spec.is_attacker?(adventurer.adventurer, adventurer)
      assert Spec.is_attacker?(party_leader.adventurer, party_leader)
    end

    test "policy check fails if actor is not attacking adventurer", %{
      adventurer: adventurer,
      other_actor: other_actor
    } do
      refute Spec.is_attacker?(adventurer, other_actor)
    end

    test "policy check fails if party leader with no adventurer tries to attack for other adventurer",
         %{party_leader_actor: actor, adventurer: adventurer} do
      refute Spec.is_attacker?(adventurer, actor)
    end

    test "policy check fails if nil adventurer is provided", %{party_leader_actor: actor} do
      refute Spec.is_attacker?(nil, actor)
    end
  end

  describe "actor_is_target?/2" do
    test "policy check succeeds if actor is the target adventurer", %{
      adventurer_actor: adventurer,
      other_actor: party_leader
    } do
      assert Spec.actor_is_target?(adventurer.adventurer, adventurer)
      assert Spec.actor_is_target?(party_leader.adventurer, party_leader)
    end

    test "policy check fails if actor is not target", %{
      adventurer: adventurer,
      other_actor: other_actor
    } do
      refute Spec.actor_is_target?(adventurer, other_actor)
    end

    test "policy check fails if party leader with no adventurer attempts to target other adventurer",
         %{party_leader_actor: actor, adventurer: adventurer} do
      refute Spec.actor_is_target?(adventurer, actor)
    end

    test "policy check fails if nil target is provided", %{party_leader_actor: actor} do
      refute Spec.actor_is_target?(nil, actor)
    end
  end

  describe "is_in_party?/2" do
    test "policy check succeeds if adventurer is in party", %{
      quest: quest,
      adventurer_actor: actor
    } do
      assert Spec.is_in_party?(quest, actor)
    end

    test "policy check succeeds if party leader is in party", %{
      quest: quest,
      party_leader_actor: actor
    } do
      assert Spec.is_in_party?(quest, actor)
    end

    test "policy check fails if adventurer is not part of current quest", %{
      quest: quest,
      other_actor: actor
    } do
      refute Spec.is_in_party?(quest, actor)
    end

    test "policy check fails if actor is adventurer belonging to a different quest", %{
      other_quest: quest,
      adventurer_actor: actor
    } do
      refute Spec.is_in_party?(quest, actor)
    end

    test "policy check fails if actor is an adventurer different from the attacking adventurer",
         %{
           other_quest: quest,
           adventurer_actor: actor
         } do
      refute Spec.is_in_party?(quest, actor)
    end
  end

  describe "is_party_leader?/2" do
    test "policy check succeeds if actor is leader of provided quest", %{
      quest: quest,
      party_leader_actor: actor
    } do
      assert Spec.is_party_leader?(quest, actor)
    end

    test "policy check fails if actor is a party leader of different quest", %{
      other_quest: quest,
      party_leader_actor: actor
    } do
      refute Spec.is_party_leader?(quest, actor)
    end

    test "policy check fails if actor is not a party leader", %{
      quest: quest,
      adventurer_actor: actor
    } do
      refute Spec.is_party_leader?(quest, actor)
    end
  end
end
