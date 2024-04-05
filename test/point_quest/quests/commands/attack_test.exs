defmodule PointQuest.Quests.Commands.AttackTest do
  use ExUnit.Case

  alias PointQuest.Error
  alias PointQuest.Quests.Commands.Attack

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  describe "changeset/2" do
    test "valid when fields present" do
      params = %{quest_id: "abcd1234", adventurer_id: "json4567", attack: 3}
      assert %{valid?: true} = Attack.changeset(%Attack{}, params)
    end

    test "errors when missing required fields" do
      params = %{quest_id: "abcd1234", adventurer_id: "json4567", attack: 3}

      for field <- [:quest_id, :adventurer_id, :attack] do
        params = Map.delete(params, field)

        assert %{valid?: false, errors: [{^field, _required}]} =
                 Attack.changeset(%Attack{}, params)
      end
    end

    test "errors when attack is not a valid attack value" do
      params = %{quest_id: "abcd1234", adventurer_id: "json4567", attack: 4}

      assert %{valid?: false, errors: [attack: {"is invalid", _reason}]} =
               Attack.changeset(%Attack{}, params)
    end
  end

  describe "new/1" do
    test "returns error tuple on validation failure" do
      params = %{quest_id: "abcd1234", adventurer_id: "json4567", attack: 3}

      for field <- [:quest_id, :adventurer_id, :attack] do
        params = Map.delete(params, field)

        assert {:error, %{valid?: false, errors: [{^field, _required}]}} =
                 Attack.new(params)
      end
    end

    test "returns ok tuple on validation success" do
      quest_id = "abcd1234"
      adventurer_id = "json4567"
      attack = 3

      params = %{quest_id: quest_id, adventurer_id: adventurer_id, attack: attack}

      assert {:ok, %Attack{quest_id: ^quest_id, adventurer_id: ^adventurer_id, attack: ^attack}} =
               Attack.new(params)
    end
  end

  describe "new!/1" do
    test "raises exception on validation failure" do
      params = %{quest_id: "abcd1234", adventurer_id: "json4567", attack: 3}

      for field <- [:quest_id, :adventurer_id, :attack] do
        params = Map.delete(params, field)

        assert_raise Ecto.InvalidChangesetError, fn -> Attack.new!(params) end
      end
    end

    test "returns Attack struct on validation success" do
      quest_id = "abcd1234"
      adventurer_id = "json4567"
      attack = 3

      params = %{quest_id: quest_id, adventurer_id: adventurer_id, attack: attack}

      assert %Attack{quest_id: ^quest_id, adventurer_id: ^adventurer_id, attack: ^attack} =
               Attack.new!(params)
    end
  end

  describe "execute/2" do
    test "returns updated quest on success", %{
      quest: %{id: quest_id},
      adventurer: %{id: adventurer_id},
      adventurer_actor: adventurer_actor
    } do
      Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest_id)

      attacked_event = %PointQuest.Quests.Event.AdventurerAttacked{
        quest_id: quest_id,
        adventurer_id: adventurer_id,
        attack: 3
      }

      assert {:ok, ^attacked_event} =
               %{quest_id: quest_id, adventurer_id: adventurer_id, attack: 3}
               |> Attack.new!()
               |> Attack.execute(adventurer_actor)

      assert_receive ^attacked_event, 500
    end

    test "succeeds if party leader is adventurer attacking", %{other_actor: actor} do
      assert {:ok, _event} =
               Attack.new!(%{
                 quest_id: actor.quest_id,
                 adventurer_id: actor.adventurer.id,
                 attack: 8
               })
               |> Attack.execute(actor)
    end

    test "fails if quest ID doesn't exist", %{adventurer: adventurer, adventurer_actor: actor} do
      ensure_attack_fails(%{
        quest_id: "made up ID",
        adventurer_id: adventurer.id,
        attack: 5,
        actor: actor,
        error: Error.NotFound.exception(resource: :quest)
      })
    end

    defp ensure_attack_fails(%{
           quest_id: quest_id,
           adventurer_id: adventurer_id,
           attack: attack,
           actor: actor,
           error: error
         }) do
      assert {:error, ^error} =
               Attack.new!(%{
                 quest_id: quest_id,
                 adventurer_id: adventurer_id,
                 attack: attack
               })
               |> Attack.execute(actor)
    end
  end
end
