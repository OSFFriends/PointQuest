defmodule PointQuest.Quests.Commands.StartQuestTest do
  use ExUnit.Case

  alias PointQuest.Quests.Event.QuestStarted
  alias PointQuest.Quests.Commands.StartQuest

  describe "new/1" do
    test "providing no params is valid" do
      assert {:ok, %StartQuest{party_leaders_adventurer: nil}} =
               StartQuest.new(%{})
    end
  end

  describe "new!/1" do
    test "providing no params is valid" do
      assert %StartQuest{party_leaders_adventurer: nil} =
               StartQuest.new!(%{})
    end

    test "failure to provide valid adventurer params results in error" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        StartQuest.new!(%{name: "borked", party_leaders_adventurer: %{class: :knight}})
      end
    end
  end

  describe "party leader adventurer" do
    test "party leader can have an adventurer" do
      assert {:ok,
              %StartQuest{
                party_leaders_adventurer: %StartQuest.PartyLeadersAdventurer{
                  name: "JSON",
                  class: :knight
                }
              }} =
               StartQuest.new(%{
                 party_leaders_adventurer: %{name: "JSON", class: :knight}
               })
    end

    test "name is required" do
      assert {:error,
              %{
                valid?: false,
                changes: %{
                  party_leaders_adventurer: %{
                    valid?: false,
                    errors: [name: {"can't be blank", [validation: :required]}]
                  }
                }
              }} =
               StartQuest.new(%{name: "test", party_leaders_adventurer: %{class: :knight}})
    end

    test "class chosen at random if not provided" do
      assert {:ok,
              %StartQuest{
                party_leaders_adventurer: %{name: "JSON", class: class}
              }} = StartQuest.new(%{name: "test", party_leaders_adventurer: %{name: "JSON"}})

      assert class in PointQuest.Quests.Adventurer.Class.NameEnum.valid_atoms()
    end

    test "class must be in ClassEnum" do
      assert {:error,
              %{
                valid?: false,
                changes: %{
                  party_leaders_adventurer: %{
                    valid?: false,
                    errors: [
                      class:
                        {"is invalid",
                         [type: PointQuest.Quests.Adventurer.Class.NameEnum, validation: :cast]}
                    ]
                  }
                }
              }} =
               StartQuest.new(%{
                 party_leaders_adventurer: %{name: "bob", class: :builder}
               })
    end
  end

  describe "execute/1" do
    test "returns new quest state" do
      {:ok, start_quest} = StartQuest.new(%{})

      assert {:ok, %QuestStarted{quest_id: quest_id}} =
               StartQuest.execute(start_quest)

      refute is_nil(quest_id)
    end

    test "errors when passed invalid changeset" do
      {:error, bad_changeset} =
        StartQuest.new(%{party_leaders_adventurer: %{name: "json", class: "fake class"}})

      assert_raise FunctionClauseError, fn -> StartQuest.execute(bad_changeset) end
    end
  end
end
