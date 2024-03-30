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
end
