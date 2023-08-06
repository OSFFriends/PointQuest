defmodule PointQuestWeb.Linear do
  @moduledoc """
  Test landing page for logging in to linear
  """
  use PointQuestWeb, :live_view

  @linear_config Application.compile_env(:point_quest, Infra.Linear)

  def render(assigns) do
    ~H"""
    <button>Linear</button>
    """
  end

  def mount(_params, _session, socket) do
    client =
      OAuth2.Client.new(
        strategy: Strategy.AuthCode,
        client_id: @linear_config[:client_id],
        client_secret: @linear_config[:client_secret],
        site: "https://linear.app",
        redirect_uri: "https://localhost:4000/linear/auth/callback"
      )

    socket = assign(socket, client: client)
    {:ok, socket}
  end
end
