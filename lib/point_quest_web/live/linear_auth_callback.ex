defmodule PointQuestWeb.LinearAuthCallback do
  @moduledoc """
  Test redirect page for getting linear code
  """
  use PointQuestWeb, :live_view
  use Tesla

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:portal, __MODULE__)[:base_url])
  plug(Tesla.Middleware.FormUrlencoded)

  @linear_config Application.compile_env(:point_quest, Infra.Linear)

  def render(assigns) do
    ~H"""
    hi #{@token}
    <button
      type="button"
      class="inline-block rounded bg-primary px-6 pb-2 pt-2.5 text-xs font-medium uppercase leading-normal text-black shadow-[0_4px_9px_-4px_#3b71ca] transition duration-150 ease-in-out hover:bg-primary-600 hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:bg-primary-600 focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:outline-none focus:ring-0 active:bg-primary-700 active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] dark:shadow-[0_4px_9px_-4px_rgba(59,113,202,0.5)] dark:hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)]"
      phx-click="get_token"
    >
      Get Token 
    </button>
    """
  end

  def handle_params(%{"code" => code}, _uri, socket) do
    socket = assign_new(socket, :code, fn -> code end)
    {:noreply, socket}
  end

  def handle_event("get_token", _params, %{assigns: %{code: code}} = socket) do
    token = get_linear_token(code) |> dbg

    {:noreply,
     push_patch(assign(socket, token: token),
       to: ~p"/linear/auth/callback?code=#{socket.assigns.code}"
     )}
  end

  def handle_event("connect-to-linear", _params, socket) do
    client_id = @linear_config[:client_id]
    redirect_url = URI.encode("http://localhost:4000/linear/auth/callback")

    url =
      "https://linear.app/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_url}&scope=read&prompt=consent"

    {:noreply, redirect(socket, external: url) |> dbg}
  end

  defp get_linear_token(code) do
    body =
      %{
        code: code,
        redirect_uri: "http://localhost:4000/linear/auth/callback",
        client_id: @linear_config[:client_id],
        client_secret: @linear_config[:client_secret],
        grant_type: "authorization_code"
      }

    {:ok, %{body: response}} =
      post("https://api.linear.app/oauth/token", body)

    %{"access_token" => token} = Jason.decode!(response)

    token
  end
end
