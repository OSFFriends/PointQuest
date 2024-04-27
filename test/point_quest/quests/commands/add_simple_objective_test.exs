defmodule PointQuest.Quests.Commands.AddSimpleObjectiveTest do
  use ExUnit.Case

  alias PointQuest.Error
  alias PointQuest.Quests.Commands.AddSimpleObjective
  alias PointQuest.Quests.Objectives.Objective
  alias PointQuest.Quests.Objectives.Questable

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  # `changeset/2`, `new/1`, and `new!/1` are all implemented from the
  # `Valuable` macro, and are not overridden in our command. As such
  # I have opted not to test them here as we have other unit tests
  # proving the functionality of the macro implementations.

  describe "execute/2" do
    test "returns objective_added event on success", %{
      quest: %{id: quest_id},
      party_leader_actor: actor
    } do
      Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest_id)

      quest_objective =
        Objective.changeset(%Objective{}, %{id: "make the test pass"})
        |> Ecto.Changeset.apply_action!(:insert)

      objective_added_event = %PointQuest.Quests.Event.ObjectiveAdded{
        quest_id: quest_id,
        objective: quest_objective
      }

      assert {:ok, ^objective_added_event} =
               %{quest_id: quest_id, quest_objective: "make the test pass"}
               |> AddSimpleObjective.new!()
               |> AddSimpleObjective.execute(actor)

      assert_received ^objective_added_event
    end

    test "fails if quest ID doesn't exist", %{party_leader_actor: actor} do
      error = Error.NotFound.exception(resource: :quest)

      assert {:error, ^error} =
               AddSimpleObjective.new!(%{quest_id: "McLovin", quest_objective: "make test fail"})
               |> AddSimpleObjective.execute(actor)
    end

    test "fails if objective is not added by party leader", %{
      quest: %{id: quest_id},
      adventurer_actor: actor
    } do
      assert {:error, :must_be_leader_of_party} =
               AddSimpleObjective.new!(%{quest_id: quest_id, quest_objective: "fail AGAIN!"})
               |> AddSimpleObjective.execute(actor)
    end
  end

  test "to_objective/1 returns objective from add_objective command", %{quest: %{id: quest_id}} do
    objective = "test protocol implementation"

    command =
      AddSimpleObjective.new!(%{
        quest_id: quest_id,
        quest_objective: objective
      })

    assert %Objective{id: ^objective, title: nil, description: nil} =
             Questable.to_objective(command)
  end
end
