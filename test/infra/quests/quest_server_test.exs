defmodule Infra.Quests.QuestServerTest do
  use ExUnit.Case, async: true

  alias Infra.Quests.QuestServer
  alias PointQuest.Quests

  describe "automatic cleanup of old sessions" do
    setup do
      quest =
        Quests.Quest.project(
          Quests.Event.QuestStarted.new!(%{
            quest_id: Nanoid.generate_non_secure(),
            name: "My Quest"
          }),
          %Quests.Quest{}
        )

      Process.flag(:trap_exit, true)

      {:ok, quest_server} = QuestServer.start_link(quest: quest, timeout: 500)

      {:ok, quest: quest, quest_server: quest_server}
    end

    test "quest dies after timeout", %{quest_server: quest_server} do
      assert_receive({:EXIT, ^quest_server, :shutdown}, 1000)
    end

    test "update prolongs life of quest", %{quest: quest, quest_server: quest_server} do
      # sending the same quest, server don't care
      Process.sleep(250)
      QuestServer.update(quest_server, quest)
      Process.sleep(250)
      QuestServer.update(quest_server, quest)

      # we're over the 500ms initial kill timeout
      refute_receive({:EXIT, ^quest_server, :shutdown}, 100)

      # should now be receiving the kill timeout
      assert_receive({:EXIT, ^quest_server, :shutdown}, 500)
    end
  end
end
