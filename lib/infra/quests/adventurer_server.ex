defmodule Infra.Quests.AdventurerServer do
  @moduledoc """
  Agent to hold adventurer state
  """

  use Agent

  def start_link(adventurer) do
    Agent.start_link(fn -> adventurer end,
      name: {:via, Registry, {Infra.Adventurer.Registry, adventurer.id}}
    )
  end
end
