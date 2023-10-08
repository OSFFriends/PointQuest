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
    teams = linear().list_teams(socket.assigns.current_user.id)
    team = List.first(teams)

    {:ok, assign(socket, teams: teams, team: team)}
  end
end
