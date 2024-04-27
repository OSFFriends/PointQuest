defmodule Infra.Quests.InMemory.Supervisor do
  @moduledoc """
  Supervisor for Distributed InMemory Quest database components
  """
  use Supervisor
  alias Infra.Quests.InMemory

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    [
      # Lookup Game Servers by Quest Id
      {Horde.Registry, keys: :unique, name: InMemory.Registry, members: :auto},
      # Manage Game Servers across the cluster
      {Horde.DynamicSupervisor,
       name: InMemory.QuestSupervisor, strategy: :one_for_one, members: :auto},
      # Projections across in memory quest servers
      InMemory.QuestStore
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
