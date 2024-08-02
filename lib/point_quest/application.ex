defmodule PointQuest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PointQuestWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:point_quest, :dns_cluster_query) || :ignore},
      {Finch, name: PointQuest.Finch},
      Infra.Quests.InMemory.Supervisor,
      Infra.Quests.SimpleInMemory.Supervisor,
      Infra.Quests.Couch.Supervisor,
      {Phoenix.PubSub, name: PointQuestWeb.PubSub},
      PointQuestWeb.Presence,
      PointQuestWeb.Endpoint
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
