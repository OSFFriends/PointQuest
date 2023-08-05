defmodule Infra.Linear do
  @moduledoc """
  Simple client for Linear requests

  Handles my naive GraphQL queries until we make it more gooder
  """
  use Tesla

  alias Infra.Linear.Records.Issue
  alias Infra.Linear.Records.Team
  alias PointQuest.QueryParser

  plug Tesla.Middleware.BaseUrl, "https://api.linear.app"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json"},
    {"Authorization", Application.get_env(:point_quest, __MODULE__)[:api_key]}
  ]

  plug Tesla.Middleware.JSON

  def get_portal_team_id() do
    body = %{query: QueryParser.list_teams([])}
    team_name = Application.get_env(:point_quest, __MODULE__)[:team_name]

    {:ok, %Tesla.Env{} = resp} = post("/graphql", body)

    [%{"id" => team_id, "name" => ^team_name}] =
      resp.body["data"]["teams"]["nodes"]
      |> Enum.filter(fn team -> team["name"] == team_name end)

    team_id
  end

  def list_teams() do
    body = %{query: QueryParser.list_teams([])}

    {:ok, %Tesla.Env{body: %{"data" => %{"teams" => %{"nodes" => teams}}}}} =
      post("/graphql", body)

    Enum.map(teams, &Ecto.embedded_load(Team, &1, :json))
  end

  def list_team_issues(team_id) do
    body = %{query: QueryParser.list_issues_for_team(id: team_id)}

    {:ok, %Tesla.Env{body: %{"data" => %{"team" => team}}}} =
      post("/graphql", body)

    # map_issues(issues)
    Infra.LinearObject.load(Team, team)
  end

  defp map_issues(issues) do
    Enum.map(issues, &Ecto.embedded_load(Issue, &1, :json))
  end
end
