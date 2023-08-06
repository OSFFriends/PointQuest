defmodule Infra.Quests.DbHelper do
  @moduledoc """
  Helper functions for in-memory DB

  Helps to quickly test the db functionality without having to remember
  the changeset shape for each component of a quest
  """
  alias PointQuest.Quests
  alias PointQuest.Quests.Quest

  @spec create_quest(
          name :: String.t(),
          party_leader :: String.t(),
          lead_from_the_front? :: boolean(),
          adventurers :: [String.t()]
        ) :: Quest.t()
  def create_quest(name, party_leader, lead_from_the_front? \\ false, adventurers \\ []) do
    params = %{
      name: name,
      party_leader: %{name: party_leader},
      lead_from_the_front: lead_from_the_front?
    }

    quest = Quests.create(params)

    result =
      if length(Enum.filter(adventurers, fn adv -> adv != party_leader end)) > 0 do
        for adventurer <- adventurers, reduce: quest do
          acc ->
            adv_params = %{
              name: adventurer
            }

            {:ok, quest} = Quests.add_adventurer_to_party(acc.id, adv_params)
            quest
        end
      else
        quest
      end

    result
  end
end
