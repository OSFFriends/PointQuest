defmodule Infra.Quests.Couch.Supervisor do
  @moduledoc """
  Supervisor for Simple InMemory Quest database components
  """
  use Supervisor
  alias Infra.Quests.Couch

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    [
      {Horde.Registry, keys: :unique, name: Couch.Registry},
      {Horde.DynamicSupervisor, name: Couch.QuestSupervisor, strategy: :one_for_one}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
