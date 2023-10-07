defmodule PointQuestWeb.Quest do
  @moduledoc """
  Retrieve and display quest information
  """
  alias PointQuest.Linear

  use PointQuestWeb, :live_view
  use Tesla

  @spec linear() :: module()
  def linear(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear)

  def render(assigns) do
    ~H"""
    <button
      :if={!@has_token?}
      type="button"
      class="inline-block rounded bg-primary px-6 pb-2 pt-2.5 text-xs font-medium leading-normal text-black shadow-[0_4px_9px_-4px_#3b71ca] transition duration-150 ease-in-out hover:bg-primary-600 hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:bg-primary-600 focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] focus:outline-none focus:ring-0 active:bg-primary-700 active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.3),0_4px_18px_0_rgba(59,113,202,0.2)] dark:shadow-[0_4px_9px_-4px_rgba(59,113,202,0.5)] dark:hover:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:focus:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)] dark:active:shadow-[0_8px_9px_-4px_rgba(59,113,202,0.2),0_4px_18px_0_rgba(59,113,202,0.1)]"
      phx-click="connect_to_linear"
    >
      Auth with Linear
    </button>
    <div :if={!is_nil(@team)} class="flex flex-col items-start self-stretch order-none gap-y-5">
      <div>
        <h2 class="text-2xl">Teams</h2>
        <%= for %{"name" => name, "id" => id} <- @teams do %>
          <p><%= name %> - <%= id %></p>
        <% end %>
      </div>
      <div>
        <h2 class="text-2xl">Issues</h2>
        <%= for issue <- linear().list_issues(@team["id"], @current_user.id) do %>
          <p>Issue: <%= issue.id %></p>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_new(:teams, fn -> [] end)
      |> assign_new(:team, fn -> nil end)
      |> assign(has_token?: linear().has_token?(socket.assigns.current_user.email))

    socket =
      if linear().has_token?(socket.assigns.current_user.email) do
        socket = assign(socket, :teams, linear().list_teams(socket.assigns.current_user.id))
        socket = assign(socket, :team, List.first(socket.assigns.teams))
        socket
      else
        socket
      end

    {:ok, socket}
  end

  def handle_info({_ref, {:ok, %{teams: teams}}}, socket) do
    {:noreply, assign(socket, teams: teams, team: List.first(teams))}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  def handle_params(%{"code" => code}, _uri, socket) do
    if connected?(socket) && !linear().has_token?(socket.assigns.current_user.email) do
      :ok =
        linear().redeem_code(
          "http://localhost:4000/quest",
          code,
          socket.assigns.current_user.id
        )

      socket = assign(socket, has_token?: true)

      Task.async(fn ->
        teams = linear().list_teams(socket.assigns.current_user.id)
        {:ok, %{teams: teams}}
      end)

      {:noreply, push_patch(socket, to: ~p"/quest")}
    else
      {:noreply, socket}
    end
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
end
