defmodule Infra.Quests.DbHelper do
  @moduledoc """
  Helper functions for in-memory DB

  Helps to quickly test the db functionality without having to remember
  the changeset shape for each component of a quest
  """
  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Quest

  @spec create_quest(
          name :: String.t(),
          party_leader :: String.t(),
          lead_from_the_front? :: boolean(),
          adventurer_names :: [String.t()]
        ) :: Quest.t()
  def create_quest(name, party_leader, lead_from_the_front? \\ false, adventurer_names \\ []) do
    adventurers =
      for adv <- adventurer_names, reduce: [] do
        acc ->
          a =
            Infra.Quests.Db.create_adventurer(
              Adventurer.create_changeset(%Adventurer{}, %{name: adv})
            )

          [%{id: a.id, name: a.name} | acc]
      end

    %Adventurer{id: pl_id, name: pl_name} =
      Infra.Quests.Db.create_adventurer(
        Adventurer.create_changeset(%Adventurer{}, %{name: party_leader})
      )

    params = %{
      name: name,
      party_leader: %{id: pl_id, name: pl_name},
      lead_from_the_front: lead_from_the_front?
    }

    quest = Quests.create(params)

    case length(Enum.filter(adventurers, fn adv -> adv != party_leader end)) > 0 do
      true ->
        for adventurer <- adventurers, reduce: quest do
          acc ->
            {:ok, quest} = Quests.add_adventurer_to_party(acc.id, adventurer)
            quest
        end

      false ->
        quest
    end
  end
end
