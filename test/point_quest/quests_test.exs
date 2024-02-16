defmodule PointQuest.QuestsTest do
  use ExUnit.Case, async: true
  alias PointQuest.Quests
  alias PointQuest.Quests.Quest

  describe "create/1" do
    test "can create a quest" do
      assert {:ok, %Quest{}} =
               Quests.create(%{name: "my quest", party_leader: %{name: "Bilbo Baggins"}})
    end

    test "missing required options results in an error" do
      # party leader is required
      assert {:error, %Ecto.Changeset{valid?: false}} =
               Quests.create(%{name: "my quest"})
    end
  end

  describe "get/1" do
    test "can get a valid quest" do
      assert {:ok, %Quest{} = quest} =
               Quests.create(%{name: "get this team", party_leader: %{name: "get it"}})

      assert {:ok, ^quest} = Quests.get(quest.id)
    end

    test "returns error for quest that doesn't exist" do
      assert {:error, :quest_not_found} = Quests.get(Ecto.UUID.generate())
    end
  end
end
