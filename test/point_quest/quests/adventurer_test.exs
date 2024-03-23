defmodule PointQuest.Quests.AdventurerTest do
  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias PointQuest.Quests.Adventurer

  describe "creating an adventurer" do
    test "required fields" do
      required_params = %{name: "my party", quest_id: "xab124D"}

      for {field, _value} <- required_params do
        missing_requied = Map.delete(required_params, field)

        assert %Changeset{valid?: false, errors: errors} =
                 Adventurer.create_changeset(%Adventurer{}, missing_requied)

        assert Keyword.has_key?(errors, field)
      end
    end

    test "class is randomly assigned if not passed" do
      for class <- [:healer, :mage, :knight] do
        assert %Changeset{valid?: true} =
                 adventurer_changeset =
                 Adventurer.create_changeset(%Adventurer{}, %{
                   name: "a #{class}",
                   class: class,
                   quest_id: "abc123"
                 })

        assert class == Changeset.get_field(adventurer_changeset, :class)
      end

      # a random one is assigned if not passed
      assert %Changeset{valid?: true} =
               adventurer_changeset =
               Adventurer.create_changeset(%Adventurer{}, %{
                 name: "another member",
                 quest_id: "abc123"
               })

      assert Changeset.get_field(adventurer_changeset, :class) != nil
    end
  end
end
