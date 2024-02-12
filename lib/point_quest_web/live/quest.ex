defmodule PointQuestWeb.Quest do
  @moduledoc """
  Retrieve and display quest information
  """
  use PointQuestWeb, :live_view
  use Tesla

  @spec linear() :: module()
  def linear(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear)

  def render(assigns) do
    ~H"""
    <div :if={!is_nil(@team)} class="flex flex-col items-start self-stretch order-none gap-y-5">
      <div>
        <h2 class="text-2xl">Teams</h2>
        <p :for={%{"name" => name, "id" => id} <- @teams}><%= name %> - <%= id %></p>
      </div>
      <div id="lists" class="grid sm:grid-cols-1 md:grid-cols-3 gap-2">
        <.live_component
          id="1"
          module={PointQuestWeb.Live.Components.List}
          list={@issues}
          list_name="Issues"
          session={@session}
        />
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        session_id = "12242ljl"
        current_user = socket.assigns.current_user.id
        teams = linear().list_teams(current_user)
        team = List.first(teams)
        issues = linear().list_issues(team["id"], current_user)
        assign(socket, teams: teams, team: team, issues: issues, session: session_id)
      else
        socket
        |> assign_new(:teams, fn -> [] end)
        |> assign_new(:team, fn -> nil end)
      end

    {:ok, socket}
  end
end
