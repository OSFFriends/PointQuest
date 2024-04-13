defmodule PointQuest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PointQuestWeb.Telemetry,
      # Start the Ecto repository
      Infra.Quests.QuestStore,
      # Registry for managing quest processes
      {Horde.Registry, keys: :unique, name: Infra.Quests.Registry, members: :auto},
      # Start the PubSub system
      {Phoenix.PubSub, name: PointQuestWeb.PubSub},
      PointQuestWeb.Presence,
      # Start Finch
      {Finch, name: PointQuest.Finch},
      {DNSCluster, query: Application.get_env(:point_quest, :dns_cluster_query) || :ignore},
      # Start the Endpoint (http/https)
      PointQuestWeb.Endpoint,
      {Horde.DynamicSupervisor,
       name: Infra.Quests.QuestSupervisor, strategy: :one_for_one, members: :auto}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PointQuest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PointQuestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
