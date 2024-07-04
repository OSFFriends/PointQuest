defmodule PointQuest.Quests.QuestTest do
  use ExUnit.Case

  alias PointQuest.Quests

  # gonna break this up into two sections, doing direct unit testing of the
  # functions and then doing integration-level testing where we exercise the
  # full command -> event -> project flow

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  describe "init/0" do
    test "returns expected initial state in tuple" do
      assert %Quests.Quest{
               attacks: [],
               quest_objective: ""
             } = Quests.Quest.init()
    end
  end

  describe "project/2" do
    test "projects the QuestStarted event with no party leader adventurer", %{
      quest: %{id: quest_id} = quest,
      party_leader: %{id: leader_id}
    } do
      event = %Quests.Event.QuestStarted{
        quest_id: quest_id,
        leader_id: leader_id,
        party_leaders_adventurer: nil
      }

      assert %Quests.Quest{
               id: ^quest_id,
               party: %Quests.Party{
                 party_leader: %Quests.PartyLeader{
                   id: ^leader_id,
                   quest_id: ^quest_id
                 },
                 adventurers: []
               },
               attacks: [],
               round_active?: false,
               quest_objective: ""
             } = Quests.Quest.project(event, quest)
    end

    test "projects the QuestStarted event with party leader adventurer", %{
      other_quest:
        %{id: quest_id, party: %{party_leader: %{id: leader_id, adventurer: adventurer}}} =
          quest
    } do
      event = %Quests.Event.QuestStarted{
        quest_id: quest_id,
        leader_id: leader_id,
        party_leaders_adventurer: adventurer
      }

      assert %Quests.Quest{
               id: ^quest_id,
               party: %Quests.Party{
                 party_leader: %{
                   id: ^leader_id,
                   quest_id: ^quest_id,
                   adventurer: ^adventurer
                 }
               }
             } = Quests.Quest.project(event, quest)
    end

    test "projects the AdventurerJoinedParty event", %{
      quest: %{id: quest_id} = quest
    } do
      {:ok, event} =
        %{
          quest_id: quest_id,
          name: "JSON",
          class: :knight
        }
        |> Quests.Commands.AddAdventurer.new!()
        |> Quests.Commands.AddAdventurer.execute()

      assert %Quests.Quest{
               id: ^quest_id,
               party: %Quests.Party{
                 adventurers: adventurers
               }
             } = Quests.Quest.project(event, quest)

      assert Enum.member?(adventurers, %Quests.Adventurer{
               name: event.name,
               class: event.class,
               id: event.adventurer_id,
               quest_id: event.quest_id
             })
    end

    test "projects the AdventurerAttacked event", %{
      quest: %{id: quest_id} = quest,
      adventurer: %{id: adventurer_id},
      adventurer_actor: actor
    } do
      {:ok, event} =
        %{
          quest_id: quest_id,
          adventurer_id: adventurer_id,
          attack: 5
        }
        |> Quests.Commands.Attack.new!()
        |> Quests.Commands.Attack.execute(actor)

      assert %Quests.Quest{
               id: ^quest_id,
               attacks: attacks
             } = Quests.Quest.project(event, quest)

      assert Enum.member?(attacks, %Quests.Attack{adventurer_id: adventurer_id, attack: 5})
    end

    test "projects RoundStarted event", %{
      quest: %{id: quest_id} = quest,
      party_leader_actor: actor
    } do
      {:ok, event} =
        %{quest_id: quest_id}
        |> Quests.Commands.StartRound.new!()
        |> Quests.Commands.StartRound.execute(actor)

      assert %Quests.Quest{
               id: ^quest_id,
               round_active?: true
             } = Quests.Quest.project(event, quest)
    end

    test "projects RoundEnded event", %{
      quest: %{id: quest_id} = quest,
      party_leader_actor: actor
    } do
      # have to start the round before I can stop it
      {:ok, _event} =
        %{quest_id: quest_id}
        |> Quests.Commands.StartRound.new!()
        |> Quests.Commands.StartRound.execute(actor)

      {:ok, event} =
        %{quest_id: quest_id}
        |> Quests.Commands.StopRound.new!()
        |> Quests.Commands.StopRound.execute(actor)

      assert %Quests.Quest{
               id: ^quest_id,
               round_active?: false
             } = Quests.Quest.project(event, quest)
    end
  end

  describe "handle/2" do
    test "StartQuest command with no party leader adventurer returns QuestStarted event" do
      command = Quests.Commands.StartQuest.new!(%{})
      init = Quests.Quest.init()

      assert {:ok, %Quests.Event.QuestStarted{}} = Quests.Quest.handle(command, init)
    end

    test "StartQuest command with party leader adventurer returns QuestStarted event" do
      command =
        Quests.Commands.StartQuest.new!(%{
          party_leaders_adventurer: %{name: "Scott Stapp", class: :mage}
        })

      init = Quests.Quest.init()

      assert {:ok,
              %Quests.Event.QuestStarted{
                party_leaders_adventurer: %{
                  name: "Scott Stapp",
                  class: :mage
                }
              }} = Quests.Quest.handle(command, init)
    end

    test "AddAdventurer command returns AdventurerJoinedParty event", %{
      quest: %{id: quest_id} = quest
    } do
      command =
        %{
          name: "JSON the great",
          class: :knight,
          quest_id: quest_id
        }
        |> Quests.Commands.AddAdventurer.new!()

      assert {:ok,
              %Quests.Event.AdventurerJoinedParty{
                quest_id: ^quest_id,
                name: "JSON the great",
                class: :knight
              }} = Quests.Quest.handle(command, quest)
    end

    test "Attack command returns AdventurerAttacked event", %{
      quest: %{id: quest_id} = quest,
      adventurer: %{id: adventurer_id}
    } do
      command =
        %{
          quest_id: quest_id,
          adventurer_id: adventurer_id,
          attack: 1
        }
        |> Quests.Commands.Attack.new!()

      assert {:ok,
              %Quests.Event.AdventurerAttacked{
                quest_id: ^quest_id,
                adventurer_id: ^adventurer_id,
                attack: 1
              }} = Quests.Quest.handle(command, quest)
    end

    test "StartRound command returns RoundStarted event", %{
      quest: %{id: quest_id} = quest
    } do
      command =
        %{
          quest_id: quest_id
        }
        |> Quests.Commands.StartRound.new!()

      {:ok,
       %{
         quest_id: ^quest_id,
         objectives: []
       }} = Quests.Quest.handle(command, quest)
    end

    test "StopRound command returns RoundEnded event", %{
      quest: %{id: quest_id} = quest
    } do
      quest = %{quest | round_active?: true}

      command =
        %{
          quest_id: quest_id
        }
        |> Quests.Commands.StopRound.new!()

      {:ok,
       %{
         quest_id: ^quest_id
       }} = Quests.Quest.handle(command, quest)
    end
  end

  describe "quest objectives functionality" do
    test "starting round moves next incomplete objective to current objective", %{
      quest: %{id: quest_id},
      party_leader_actor: actor
    } do
      %{quest_id: quest_id, quest_objective: "test1"}
      |> Quests.Commands.AddSimpleObjective.new!()
      |> Quests.Commands.AddSimpleObjective.execute(actor)

      %{quest_id: quest_id, quest_objective: "test2"}
      |> Quests.Commands.AddSimpleObjective.new!()
      |> Quests.Commands.AddSimpleObjective.execute(actor)

      # ensure we have 2 incomplete objectives
      {:ok, %{objectives: objectives} = quest} = PointQuest.quest_repo().get_quest_by_id(quest_id)
      assert length(Enum.filter(objectives, fn o -> o.status == :incomplete end)) == 2

      command = Quests.Commands.StartRound.new!(%{quest_id: quest_id})

      {:ok,
       %{
         quest_id: ^quest_id,
         objectives: updated_objectives
       }} = Quests.Quest.handle(command, quest)

      updated_objectives = Enum.group_by(updated_objectives, fn o -> o.status end)

      assert length(updated_objectives.current) == 1
      assert updated_objectives.current |> List.first() |> Map.get(:title) == "test1"

      assert length(updated_objectives.incomplete) == 1
      assert updated_objectives.incomplete |> List.first() |> Map.get(:title) == "test2"
    end

    test "stopping round moves current objective to complete", %{
      quest: %{id: quest_id},
      party_leader_actor: actor
    } do
      %{quest_id: quest_id, quest_objective: "test1"}
      |> Quests.Commands.AddSimpleObjective.new!()
      |> Quests.Commands.AddSimpleObjective.execute(actor)

      %{quest_id: quest_id}
      |> Quests.Commands.StartRound.new!()
      |> Quests.Commands.StartRound.execute(actor)

      {:ok, %{objectives: objectives} = quest} = PointQuest.quest_repo().get_quest_by_id(quest_id)
      assert length(Enum.filter(objectives, fn o -> o.status == :current end)) == 1

      command =
        %{quest_id: quest_id}
        |> Quests.Commands.StopRound.new!()

      {:ok,
       %{
         quest_id: ^quest_id,
         objectives: updated_objectives
       }} = Quests.Quest.handle(command, quest)

      updated_objectives = Enum.group_by(updated_objectives, fn o -> o.status end)

      assert length(updated_objectives.complete) == 1
      assert updated_objectives.complete |> List.first() |> Map.get(:title) == "test1"
    end
  end
end
