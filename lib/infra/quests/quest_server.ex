defmodule Infra.Quests.QuestServer do
  @moduledoc """
  Agent to hold quest state
  """

  use Agent

  def start_link(quest) do
    Agent.start_link(fn -> quest end, name: {:via, Registry, {Infra.Quests.Registry, quest.id}})
  end
end
