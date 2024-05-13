defmodule PointQuest.Quests.Commands.StartRoundTest do
  use ExUnit.Case

  alias PointQuest.Quests.Commands.StartRound
  alias PointQuest.Quests.Event.RoundStarted

  require PointQuest.Quests.Telemetry

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  describe "new/1" do
    test "returns ok tuple if valid", %{quest: %{id: quest_id}} do
      assert {:ok, %StartRound{quest_id: ^quest_id}} =
               StartRound.new(%{quest_id: quest_id})
    end

    test "returns error tuple if quest id omitted" do
      assert {:error, %{valid?: false}} = StartRound.new(%{})
    end
  end

  describe "new!/1" do
    test "returns command if valid", %{quest: %{id: quest_id}} do
      assert %StartRound{quest_id: ^quest_id} = StartRound.new!(%{quest_id: quest_id})
    end

    test "throws if quest id is omitted" do
      assert_raise Ecto.InvalidChangesetError, fn -> StartRound.new!(%{}) end
    end
  end

  describe "changeset/2" do
    test "returns changeset if valid" do
      assert %{valid?: true, changes: %{quest_id: "abc123"}} =
               StartRound.changeset(%StartRound{}, %{quest_id: "abc123"})
    end

    test "returns error changeset if invalid" do
      assert %{valid?: false, errors: [quest_id: {"can't be blank", _validation}]} =
               StartRound.changeset(%StartRound{}, %{})
    end
  end

  describe "execute/2" do
    test "returns event when successful", %{quest: %{id: quest_id}, party_leader_actor: actor} do
      assert {:ok, %RoundStarted{quest_id: ^quest_id}} =
               %{quest_id: quest_id}
               |> StartRound.new!()
               |> StartRound.execute(actor)
    end

    test "fires rounds started telemetry event", %{quest: quest, party_leader_actor: actor} do
      ref =
        :telemetry_test.attach_event_handlers(
          self(),
          [
            PointQuest.Quests.Telemetry.round_started(:stop)
          ]
        )

      assert {:ok, %RoundStarted{} = round_started} =
               %{quest_id: quest.id}
               |> StartRound.new!()
               |> StartRound.execute(actor)

      assert_receive {
        PointQuest.Quests.Telemetry.round_started(:stop),
        ^ref,
        _measurements,
        %{event: ^round_started, actor: ^actor}
      }
    end

    test "returns error if quest doesn't exist", %{party_leader_actor: actor} do
      assert {:error, %PointQuest.Error.NotFound{resource: :quest}} =
               %{quest_id: "abc123"}
               |> StartRound.new!()
               |> StartRound.execute(actor)
    end

    test "returns error if actor is not party leader of provided quest", %{
      quest: %{id: quest_id},
      other_actor: actor
    } do
      assert {:error, :must_be_leader_of_quest_party} =
               %{quest_id: quest_id}
               |> StartRound.new!()
               |> StartRound.execute(actor)
    end

    test "returns error if round is started by non-party leader", %{
      quest: %{id: quest_id},
      adventurer_actor: actor
    } do
      assert {:error, :must_be_leader_of_quest_party} =
               %{quest_id: quest_id}
               |> StartRound.new!()
               |> StartRound.execute(actor)
    end

    test "returns error if round is already active on provided quest", %{
      quest: %{id: quest_id},
      party_leader_actor: actor
    } do
      assert {:ok, %RoundStarted{}} =
               %{quest_id: quest_id}
               |> StartRound.new!()
               |> StartRound.execute(actor)

      assert {:error, :round_already_active} =
               %{quest_id: quest_id}
               |> StartRound.new!()
               |> StartRound.execute(actor)
    end
  end
end
