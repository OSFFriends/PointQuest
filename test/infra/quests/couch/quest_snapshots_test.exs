defmodule Infra.Quests.Couch.QuestSnapshotsTest do
  use ExUnit.Case, async: true

  alias PointQuest.Quests.Commands
  alias Infra.Quests.Couch

  @moduletag :couch

  describe "get_snapshot/2" do
    test "requesting latest when no snapshots exist" do
      assert Couch.QuestSnapshots.get_snapshot("non-existent-quest", :latest) == nil
    end

    test "requesting latest when one does exist" do
      {:ok, quest_started} =
        Commands.StartQuest.execute(
          Commands.StartQuest.new!(%{
            party_leaders_adventurer: %{name: "snapper", class: "healer"}
          }),
          quest_repo: Couch.Db
        )

      assert {:ok, %{party: %{party_leader: party_leader}} = quest} =
               Couch.Db.get_quest_by_id(quest_started.quest_id)

      Couch.QuestSnapshots.write_snapshot(%{version: quest_started.id, snapshot: quest})

      actor = PointQuest.Authentication.create_actor(party_leader)

      assert %{snapshot: ^quest} =
               Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, add_adventurer} =
        Commands.AddAdventurer.execute(
          Commands.AddAdventurer.new!(%{
            name: "new latest boi",
            class: :healer,
            quest_id: quest_started.quest_id
          }),
          quest_repo: Couch.Db
        )

      assert {:ok, quest} = Couch.Db.get_quest_by_id(quest_started.quest_id)
      Couch.QuestSnapshots.write_snapshot(%{version: add_adventurer.id, snapshot: quest})

      assert %{snapshot: ^quest} =
               add_adventurer_snap =
               Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, round_started} =
        Commands.StartRound.execute(
          Commands.StartRound.new!(%{
            quest_id: quest_started.quest_id
          }),
          actor,
          quest_repo: Couch.Db
        )

      assert {:ok, quest} = Couch.Db.get_quest_by_id(quest_started.quest_id)
      Couch.QuestSnapshots.write_snapshot(%{version: round_started.id, snapshot: quest})

      round_started_snap = Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)
      refute round_started_snap == add_adventurer_snap
    end

    test "requesting snapshot before a version when last snapshot is that event" do
      {:ok, quest_started} =
        Commands.StartQuest.execute(
          Commands.StartQuest.new!(%{
            party_leaders_adventurer: %{name: "snapper", class: "healer"}
          }),
          quest_repo: Couch.Db
        )

      assert {:ok, %{party: %{party_leader: party_leader}} = quest} =
               Couch.Db.get_quest_by_id(quest_started.quest_id)

      Couch.QuestSnapshots.write_snapshot(%{version: quest_started.id, snapshot: quest})

      actor = PointQuest.Authentication.create_actor(party_leader)

      assert %{snapshot: ^quest} =
               Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, add_adventurer} =
        Commands.AddAdventurer.execute(
          Commands.AddAdventurer.new!(%{
            name: "new latest boi",
            class: :healer,
            quest_id: quest_started.quest_id
          }),
          quest_repo: Couch.Db
        )

      assert {:ok, quest} = Couch.Db.get_quest_by_id(quest_started.quest_id)
      Couch.QuestSnapshots.write_snapshot(%{version: add_adventurer.id, snapshot: quest})

      assert %{snapshot: ^quest} =
               add_adventurer_snap =
               Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, round_started} =
        Commands.StartRound.execute(
          Commands.StartRound.new!(%{
            quest_id: quest_started.quest_id
          }),
          actor,
          quest_repo: Couch.Db
        )

      assert {:ok, quest} = Couch.Db.get_quest_by_id(quest_started.quest_id)
      Couch.QuestSnapshots.write_snapshot(%{version: round_started.id, snapshot: quest})

      before_round_started_snap =
        Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, {:before, round_started.id})

      assert before_round_started_snap == add_adventurer_snap
    end

    test "requesting snapshot before version when event is not last snapshot" do
      {:ok, quest_started} =
        Commands.StartQuest.execute(
          Commands.StartQuest.new!(%{
            party_leaders_adventurer: %{name: "snapper", class: "healer"}
          }),
          quest_repo: Couch.Db
        )

      assert {:ok, %{party: %{party_leader: party_leader}} = quest} =
               Couch.Db.get_quest_by_id(quest_started.quest_id)

      Couch.QuestSnapshots.write_snapshot(%{version: quest_started.id, snapshot: quest})

      actor = PointQuest.Authentication.create_actor(party_leader)

      assert %{snapshot: ^quest} =
               Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, add_adventurer} =
        Commands.AddAdventurer.execute(
          Commands.AddAdventurer.new!(%{
            name: "new latest boi",
            class: :healer,
            quest_id: quest_started.quest_id
          }),
          quest_repo: Couch.Db
        )

      assert {:ok, quest} = Couch.Db.get_quest_by_id(quest_started.quest_id)
      Couch.QuestSnapshots.write_snapshot(%{version: add_adventurer.id, snapshot: quest})

      assert %{snapshot: ^quest} =
               Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, round_started} =
        Commands.StartRound.execute(
          Commands.StartRound.new!(%{
            quest_id: quest_started.quest_id
          }),
          actor,
          quest_repo: Couch.Db
        )

      assert {:ok, quest} = Couch.Db.get_quest_by_id(quest_started.quest_id)
      Couch.QuestSnapshots.write_snapshot(%{version: round_started.id, snapshot: quest})

      latest_snapshot = Couch.QuestSnapshots.get_snapshot(quest_started.quest_id, :latest)

      {:ok, add_adventurer_new} =
        Commands.AddAdventurer.execute(
          Commands.AddAdventurer.new!(%{
            name: "newer latest boi",
            class: :healer,
            quest_id: quest_started.quest_id
          }),
          quest_repo: Couch.Db
        )

      before_last_event =
        Couch.QuestSnapshots.get_snapshot(
          quest_started.quest_id,
          {:before, add_adventurer_new.id}
        )

      assert before_last_event == latest_snapshot
    end
  end
end
