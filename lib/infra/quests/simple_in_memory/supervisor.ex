defmodule Infra.Quests.SimpleInMemory.Supervisor do
  @moduledoc """
  Supervisor for Simple InMemory Quest database components
  """
  use Supervisor
  alias Infra.Quests.SimpleInMemory

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    [
      {Registry, keys: :unique, name: SimpleInMemory.Registry},
      {DynamicSupervisor, name: SimpleInMemory.QuestSupervisor, strategy: :one_for_one}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
