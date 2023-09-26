defmodule PointQuestWeb.Linear do
  @moduledoc """
  Test landing page for logging in to linear
  """
  use PointQuestWeb, :live_view

  @linear_config Application.compile_env(:point_quest, Infra.Linear)

  def render(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-block rounded bg-primary px-6 pb-2 pt-2.5 text-xs font-medium uppercase leading-normal text-black shadow-[0_4px_9px_-4px_#3b71ca] transition duration-150 ease-in-out hover:bg-primary-600 hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:bg-primary-600 focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:outline-none focus:ring-0 active:bg-primary-700 active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] dark:shadow-[0_4px_9px_-4px_rgba(59,113,202,0.5)] dark:hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)]"
      phx-click="connect-to-linear"
    >
      Linear
    </button>
    """
  end

  def mount(_params, _session, socket) do
    dbg()

    {:ok, socket}
  end

  def handle_event("connect-to-linear", _params, socket) do
    client_id = @linear_config[:client_id]
    redirect_url = URI.encode("http://localhost:4000/linear/auth/callback")

    url =
      "https://linear.app/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_url}&scope=read&prompt=consent"

    {:noreply, redirect(socket, external: url) |> dbg}
  end
end
