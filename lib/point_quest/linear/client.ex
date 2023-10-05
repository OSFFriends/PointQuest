defmodule PointQuest.Linear.Client do
  @moduledoc """
  Client for managing the HTTP capabilities for Linear
  """
  alias PointQuest.Behaviour.Linear.Client

  @linear_config Application.compile_env(:point_quest, Infra.Linear)

  @behaviour Client

  @spec repo() :: module()
  def repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Repo)

  def post(query, user_id) do
    client(user_id)
    |> Tesla.post("/graphql", %{query: query})
  end

  @impl Client
  def token_from_code(redirect_uri, code) do
    body = %{
      code: code,
      redirect_uri: redirect_uri,
      client_id: @linear_config[:client_id],
      client_secret: @linear_config[:client_secret],
      grant_type: "authorization_code"
    }

    {:ok, %{body: response}} =
      Tesla.client([Tesla.Middleware.FormUrlencoded])
      |> Tesla.post("/oauth/token", body)
      |> dbg

    Jason.decode!(response)
  end

  def client(user_id) do
    {:ok, %{token: token}} = repo().get_token_for_user(user_id)

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.linear.app"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.BearerAuth, token: token}
    ]

    Tesla.client(middleware)
  end
end
