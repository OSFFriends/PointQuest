defmodule PointQuest.Quests.Commands.AttackTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias PointQuest.Quests.Commands.Attack
  alias PointQuest.Quests.Commands.StartQuest
  alias PointQuest.Quests.Commands.AddAdventurer

  setup do
    {:ok, %{party_leader: party_leader} = quest} =
      StartQuest.new!(%{name: "proper quest"}) |> StartQuest.execute()

    {:ok, other_quest} =
      StartQuest.new!(%{
        name: "Steve's Shenanigans",
        party_leaders_adventurer: %{name: "Stevey Beevey", class: :mage}
      })
      |> StartQuest.execute()

    {:ok, %{adventurers: [adventurer | _rest]} = quest, _event} =
      AddAdventurer.new!(%{name: "Sir Stephen Bolton", class: :knight, quest_id: quest.id})
      |> AddAdventurer.execute()

    party_leader_actor = %PointQuest.Authentication.Actor.PartyLeader{
      quest_id: quest.id,
      leader_id: party_leader.id,
      adventurer: nil
    }

    adventurer_actor = %PointQuest.Authentication.Actor.Adventurer{
      quest_id: quest.id,
      adventurer: adventurer
    }

    other_actor = %PointQuest.Authentication.Actor.PartyLeader{
      quest_id: other_quest.id,
      leader_id: other_quest.party_leader.id,
      adventurer: other_quest.party_leader.adventurer
    }

    {:ok,
     %{
       quest: quest,
       other_quest: other_quest,
       party_leader: party_leader,
       adventurer: adventurer,
       party_leader_actor: party_leader_actor,
       adventurer_actor: adventurer_actor,
       other_actor: other_actor
     }}
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

      assert {:ok,
              %PointQuest.Quests.Quest{
                id: ^quest_id,
                adventurers: [%{id: ^adventurer_id}],
                attacks: [%PointQuest.Quests.Attack{adventurer_id: ^adventurer_id, attack: 3}]
              },
              ^attacked_event} =
               Attack.new!(%{quest_id: quest_id, adventurer_id: adventurer_id, attack: 3})
               |> Attack.execute(adventurer_actor)

      assert_receive ^attacked_event, 500
    end

    test "succeeds if party leader is adventurer attacking", %{other_actor: actor} do
      assert {:ok, _quest, _event} =
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
        error: :quest_not_found
      })
    end
  end

  describe "execute/2 policy checking" do
    test "policy check fails if adventurer is not part of current quest", %{
      quest: quest,
      other_actor: %{adventurer: other_adventurer} = actor
    } do
      ensure_attack_fails(%{
        quest_id: quest.id,
        adventurer_id: other_adventurer.id,
        attack: 3,
        actor: actor,
        error: "attack disallowed"
      })

      ensure_quest_not_updated(quest.id)
    end

    test "policy check fails if actor is not attacking adventurer", %{
      quest: quest,
      adventurer: adventurer,
      other_actor: other_actor
    } do
      ensure_attack_fails(%{
        quest_id: quest.id,
        adventurer_id: adventurer.id,
        attack: 1,
        actor: other_actor,
        error: "attack disallowed"
      })

      ensure_quest_not_updated(quest.id)
    end

    test "policy check fails if party leader with no adventurer tries to attack for other adventurer",
         %{party_leader_actor: actor, adventurer: adventurer} do
      ensure_attack_fails(%{
        quest_id: actor.quest_id,
        adventurer_id: adventurer.id,
        attack: 1,
        actor: actor,
        error: "attack disallowed"
      })

      ensure_quest_not_updated(actor.quest_id)
    end

    test "policy check fails if actor is adventurer belonging to a different quest", %{
      other_quest: %{id: quest_id},
      adventurer_actor: %{adventurer: adventurer} = actor
    } do
      ensure_attack_fails(%{
        quest_id: quest_id,
        adventurer_id: adventurer.id,
        attack: 3,
        actor: actor,
        error: "attack disallowed"
      })

      ensure_quest_not_updated(quest_id)
    end

    test "policy check fails if actor is an adventurer different from the attacking adventurer",
         %{
           other_quest: %{id: quest_id},
           adventurer_actor: actor,
           other_actor: %{adventurer: %{id: adventurer_id}}
         } do
      ensure_attack_fails(%{
        quest_id: quest_id,
        adventurer_id: adventurer_id,
        attack: 3,
        actor: actor,
        error: "attack disallowed"
      })

      ensure_quest_not_updated(quest_id)
    end
  end

  defp ensure_attack_fails(%{
         quest_id: quest_id,
         adventurer_id: adventurer_id,
         attack: attack,
         actor: actor,
         error: error
       }) do
    log =
      capture_log(fn ->
        assert {:error, ^error} =
                 Attack.new!(%{
                   quest_id: quest_id,
                   adventurer_id: adventurer_id,
                   attack: attack
                 })
                 |> Attack.execute(actor)
      end)

    actor_id = PointQuest.Authentication.Actor.get_actor_id(actor)

    assert log =~
             "Adventurer #{actor_id} failed to attack in quest #{quest_id}"
  end

  defp ensure_quest_not_updated(quest_id) do
    {:ok, %PointQuest.Quests.Quest{attacks: attacks} = _quest} =
      Infra.Quests.Db.get_quest_by_id(quest_id)

    assert Enum.empty?(attacks)
  end
end
