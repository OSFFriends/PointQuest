defmodule Infra.Linear do
  @moduledoc """
  Simple client for Linear requests

  Handles my naive GraphQL queries until we make it more gooder
  """
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.linear.app"

  plug Tesla.Middleware.Headers, [
    {"content-type", "application/json"},
    {"Authorization", Application.get_env(:point_quest, __MODULE__)[:api_key]}
  ]

  plug Tesla.Middleware.JSON

  def get_portal_team_id() do
    body = "{\"query\": \"{teams { nodes { id name }}}\"}"

    {:ok, %Tesla.Env{} = resp} = post("/graphql", body)

    [%{"id" => team_id, "name" => "PAYME"}] =
      resp.body["data"]["teams"]["nodes"] |> Enum.filter(fn team -> team["name"] == "PAYME" end)

    team_id
  end
end
