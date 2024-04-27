defmodule Infra.Quests.SimpleInMemory.EventServer do
  use Agent
  alias PointQuest.Quests.Quest

  def start_link(opts) do
    Agent.start_link(fn -> [] end,
      name: {:via, Registry, {Infra.Quests.SimpleInMemory.Registry, opts[:quest_id]}}
    )
  end

  def add_event(event_store, event) do
    Agent.update(event_store, fn events ->
      [event | events]
    end)
  end

  def get_quest(event_store) do
    Agent.get(event_store, fn events ->
      {:ok, quest} = Quest.init()

      events
      |> Enum.reverse()
      |> Enum.reduce(quest, &Quest.project/2)
    end)
  end
end
