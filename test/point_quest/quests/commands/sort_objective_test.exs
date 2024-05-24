defmodule PointQuest.Quests.Commands.SortObjectiveTest do
  use ExUnit.Case

  alias PointQuest.Quests.Commands.AddSimpleObjective
  alias PointQuest.Quests.Commands.SortObjective
  alias PointQuest.Quests.Event

  setup do
    {:ok, QuestSetupHelper.setup()}
  end

  test "sorting to top of list emits event with correctly sorted objectives", %{
    quest: %{id: quest_id},
    party_leader_actor: actor
  } do
    Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest_id)

    %{quest_id: quest_id, quest_objective: "quest 1"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    %{quest_id: quest_id, quest_objective: "quest 2"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    assert_received %Event.ObjectiveAdded{objectives: _obj}
    assert_received %Event.ObjectiveAdded{objectives: objectives}

    first = List.first(objectives)
    %{id: objective_id} = moving_objective = List.last(objectives)
    sorted_objective = %{moving_objective | sort_order: first.sort_order - 0.01}

    %{quest_id: quest_id, objective_id: objective_id, sort_order: first.sort_order - 0.01}
    |> SortObjective.new!()
    |> SortObjective.execute(actor)

    assert_received %Event.ObjectiveSorted{objectives: objectives}
    assert ^sorted_objective = List.first(objectives)
    assert ^first = List.last(objectives)
  end

  test "sorting to bottom of list emits event with correctly sorted objectives", %{
    quest: %{id: quest_id},
    party_leader_actor: actor
  } do
    Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest_id)

    %{quest_id: quest_id, quest_objective: "quest 1"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    %{quest_id: quest_id, quest_objective: "quest 2"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    assert_received %Event.ObjectiveAdded{objectives: _obj}
    assert_received %Event.ObjectiveAdded{objectives: objectives}

    %{id: objective_id} = moving_objective = List.first(objectives)
    last = List.last(objectives)
    sorted_objective = %{moving_objective | sort_order: last.sort_order + 0.01}

    %{quest_id: quest_id, objective_id: objective_id, sort_order: last.sort_order + 0.01}
    |> SortObjective.new!()
    |> SortObjective.execute(actor)

    assert_received %Event.ObjectiveSorted{objectives: objectives}
    assert ^last = List.first(objectives)
    assert ^sorted_objective = List.last(objectives)
  end

  test "sorting to middle of list emits event with correctly sorted objectives", %{
    quest: %{id: quest_id},
    party_leader_actor: actor
  } do
    Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest_id)

    %{quest_id: quest_id, quest_objective: "quest 1"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    %{quest_id: quest_id, quest_objective: "quest 2"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    %{quest_id: quest_id, quest_objective: "quest 3"}
    |> AddSimpleObjective.new!()
    |> AddSimpleObjective.execute(actor)

    assert_received %Event.ObjectiveAdded{objectives: _obj}
    assert_received %Event.ObjectiveAdded{objectives: _obj}
    assert_received %Event.ObjectiveAdded{objectives: objectives}

    first = List.first(objectives)
    middle = Enum.at(objectives, 1)
    %{id: objective_id} = moving_objective = List.last(objectives)

    sorted_objective = %{
      moving_objective
      | sort_order: (first.sort_order + middle.sort_order) / 2
    }

    %{
      quest_id: quest_id,
      objective_id: objective_id,
      sort_order: (first.sort_order + middle.sort_order) / 2
    }
    |> SortObjective.new!()
    |> SortObjective.execute(actor)

    assert_received %Event.ObjectiveSorted{objectives: objectives}
    assert ^sorted_objective = Enum.at(objectives, 1)
    assert ^middle = List.last(objectives)
  end
end
