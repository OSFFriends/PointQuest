defmodule Infra.Quests.InMemory.QuestServerTest do
  use ExUnit.Case, async: true

  alias Infra.Quests.InMemory.QuestServer
  alias PointQuest.Quests

  describe "automatic cleanup of old sessions" do
    setup do
      quest = Quests.Quest.init()

      quest =
        Quests.Quest.project(
          Quests.Event.QuestStarted.new!(%{
            leader_id: Nanoid.generate_non_secure(),
            quest_id: Nanoid.generate_non_secure(),
            name: "My Quest"
          }),
          quest
        )

      Process.flag(:trap_exit, true)

      {:ok, quest_server} =
        QuestServer.start_link(quest_id: Nanoid.generate_non_secure(), timeout: 500)

      {:ok, quest: quest, quest_server: quest_server}
    end

    test "quest dies after timeout", %{quest_server: quest_server} do
      assert_receive({:EXIT, ^quest_server, :shutdown}, 1000)
    end

    test "update prolongs life of quest", %{quest: quest, quest_server: quest_server} do
      event =
        Quests.Event.AdventurerJoinedParty.new!(%{
          quest_id: quest.id,
          name: "New Adventurer",
          class: "mage"
        })

      Process.sleep(250)
      QuestServer.add_event(quest_server, event)
      Process.sleep(250)
      QuestServer.add_event(quest_server, event)

      # we're over the 500ms initial kill timeout
      refute_receive({:EXIT, ^quest_server, :shutdown}, 100)

      # should now be receiving the kill timeout
      assert_receive({:EXIT, ^quest_server, :shutdown}, 500)
    end
  end

  describe "projection snappshotting" do
    test "snapshot is taken after `max_events` number of events have been received" do
      initial_quest = Quests.Quest.init()
      quest_id = Nanoid.generate_non_secure()
      {:ok, quest_server} = QuestServer.start_link(quest_id: quest_id, max_events: 2)

      # event 1
      quest_started =
        QuestServer.add_event(
          quest_server,
          Quests.Event.QuestStarted.new!(%{
            leader_id: Nanoid.generate_non_secure(),
            quest_id: quest_id,
            name: "My Quest"
          })
        )

      {:ok, event_1_projection} = Infra.Quests.InMemory.Db.get_quest_by_id(quest_id)

      # snapshot not taken yet
      assert ^initial_quest = QuestServer.get_snapshot(quest_server)
      assert [^quest_started] = QuestServer.get_events(quest_server)

      # event 2
      adventurer_joined_1 =
        QuestServer.add_event(
          quest_server,
          Quests.Event.AdventurerJoinedParty.new!(%{
            quest_id: quest_id,
            name: "Pre Snappy Boi",
            class: "mage"
          })
        )

      {:ok, event_2_projection} = Infra.Quests.InMemory.Db.get_quest_by_id(quest_id)

      # snapshot not taken yet
      assert ^initial_quest = QuestServer.get_snapshot(quest_server)

      # event 3
      adventurer_joined_2 =
        QuestServer.add_event(
          quest_server,
          Quests.Event.AdventurerJoinedParty.new!(%{
            quest_id: quest_id,
            name: "Snappy Boi",
            class: "healer"
          })
        )

      assert ^event_1_projection = QuestServer.get_snapshot(quest_server)
      assert [^adventurer_joined_1, ^adventurer_joined_2] = QuestServer.get_events(quest_server)

      # event 4
      adventurer_joined_3 =
        QuestServer.add_event(
          quest_server,
          Quests.Event.AdventurerJoinedParty.new!(%{
            quest_id: quest_id,
            name: "Again Snappy Boi",
            class: "healer"
          })
        )

      assert ^event_2_projection = QuestServer.get_snapshot(quest_server)
      assert [^adventurer_joined_2, ^adventurer_joined_3] = QuestServer.get_events(quest_server)
    end
  end
end
