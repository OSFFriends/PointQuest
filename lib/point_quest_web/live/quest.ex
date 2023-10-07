defmodule PointQuestWeb.Quest do
  @moduledoc """
  Retrieve and display quest information
  """
  alias PointQuest.Linear

  use PointQuestWeb, :live_view
  use Tesla

  def render(assigns) do
    ~H"""
    <button
      :if={!@has_token?}
      type="button"
      class="inline-block rounded bg-primary px-6 pb-2 pt-2.5 text-xs font-medium uppercase leading-normal text-black shadow-[0_4px_9px_-4px_#3b71ca] transition duration-150 ease-in-out hover:bg-primary-600 hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:bg-primary-600 focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:outline-none focus:ring-0 active:bg-primary-700 active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] dark:shadow-[0_4px_9px_-4px_rgba(59,113,202,0.5)] dark:hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)]"
      phx-click="connect_to_linear"
    >
      Sync To Linear
    </button>
    <button
      type="button"
      class="inline-block rounded bg-primary px-6 pb-2 pt-2.5 text-xs font-medium uppercase leading-normal text-black shadow-[0_4px_9px_-4px_#3b71ca] transition duration-150 ease-in-out hover:bg-primary-600 hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:bg-primary-600 focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:outline-none focus:ring-0 active:bg-primary-700 active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] dark:shadow-[0_4px_9px_-4px_rgba(59,113,202,0.5)] dark:hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)]"
      phx-click="get_teams"
    >
      Try get teams
    </button>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, has_token?: Linear.has_token?(socket.assigns.current_user.email))

    {:ok, socket}
  end

  def handle_params(%{"code" => code}, _uri, socket) do
    if connected?(socket) && !Linear.has_token?(socket.assigns.current_user.email) do
      :ok =
        Linear.redeem_code(
          "http://localhost:4000/quest",
          code,
          socket.assigns.current_user.id
        )
    end

    {:noreply, push_patch(socket, to: ~p"/quest")}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("connect_to_linear", _params, socket) do
    client_id = Application.get_env(:point_quest, Infra.Linear)[:client_id]
    redirect_url = URI.encode("http://localhost:4000/quest")

    url =
      "https://linear.app/oauth/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_url}&scope=read&prompt=consent"

    {:noreply, redirect(socket, external: url)}
  end

  def handle_event("get_teams", _params, socket) do
    Linear.list_teams(socket.assigns.current_user.id) |> dbg()
    {:noreply, socket}
  end
end
