defmodule PointQuest.Quests.Commands.StopRoundTest do
  use ExUnit.Case

  alias PointQuest.Quests.Commands.StartRound
  alias PointQuest.Quests.Commands.StopRound
  alias PointQuest.Quests.Event.RoundEnded
  alias PointQuest.Quests.Event.RoundStarted

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  describe "new/1" do
    test "returns ok tuple if valid", %{quest: %{id: quest_id}} do
      assert {:ok, %StopRound{quest_id: ^quest_id}} =
               StopRound.new(%{quest_id: quest_id})
    end

    test "returns error tuple if quest id is omitted" do
      assert {:error, %{valid?: false}} = StopRound.new(%{})
    end
  end

  describe "new!/1" do
    test "returns command if valid", %{quest: %{id: quest_id}} do
      assert %StopRound{quest_id: ^quest_id} = StopRound.new!(%{quest_id: quest_id})
    end

    test "throws if quest id is omitted" do
      assert_raise Ecto.InvalidChangesetError, fn -> StopRound.new!(%{}) end
    end
  end

  describe "changeset/2" do
    test "returns changeset if valid", %{quest: %{id: quest_id}} do
      assert %{valid?: true, changes: %{quest_id: ^quest_id}} =
               StopRound.changeset(%StopRound{}, %{quest_id: quest_id})
    end

    test "returns error if changeset is invalid" do
      assert %{valid?: false, errors: [quest_id: {"can't be blank", _validation}]} =
               StopRound.changeset(%StopRound{}, %{})
    end
  end

  describe "execute/2" do
    test "returns event when successful", %{quest: %{id: quest_id}, party_leader_actor: actor} do
      # start the round
      assert {:ok, %RoundStarted{quest_id: ^quest_id}} =
               %{quest_id: quest_id}
               |> StartRound.new!()
               |> StartRound.execute(actor)

      assert {:ok, %RoundEnded{quest_id: ^quest_id}} =
               %{quest_id: quest_id}
               |> StopRound.new!()
               |> StopRound.execute(actor)
    end

    test "returns error if quest doesn't exist", %{party_leader_actor: actor} do
      assert {:error, %PointQuest.Error.NotFound{resource: :quest}} =
               %{quest_id: "abc123"}
               |> StopRound.new!()
               |> StopRound.execute(actor)
    end

    test "returns error if actor is not leader of provided quest", %{
      quest: %{id: quest_id},
      other_actor: actor
    } do
      assert {:error, :must_be_leader_of_quest_party} =
               %{quest_id: quest_id}
               |> StopRound.new!()
               |> StopRound.execute(actor)
    end

    test "returns error if round is started by non-party leader", %{
      quest: %{id: quest_id},
      adventurer_actor: actor
    } do
      assert {:error, :must_be_leader_of_quest_party} =
               %{quest_id: quest_id}
               |> StopRound.new!()
               |> StopRound.execute(actor)
    end

    test "returns error if round is already active on provided quest", %{
      quest: %{id: quest_id},
      party_leader_actor: actor
    } do
      assert {:error, :round_not_active} =
               %{quest_id: quest_id}
               |> StopRound.new!()
               |> StopRound.execute(actor)
    end
  end
end
