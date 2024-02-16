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
    <div class="flex flex-row items-start gap-y-5">
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
      <div>
        <p :if={not is_nil(@current_ticket)}><%= @current_ticket %></p>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    session_id = "12242ljl"
    current_user = socket.assigns.current_user.id
    teams = linear().list_teams(current_user)
    team = List.first(teams)
    issues = linear().list_issues(team["id"], current_user)

    socket =
      assign(socket,
        teams: teams,
        team: team,
        issues: issues,
        session: session_id,
        current_ticket: nil
      )

    {:ok, socket}
  end

  def handle_event("update-sorting", params, socket) do
    message = {:list_updated, params}
    Phoenix.PubSub.broadcast(PointQuest.PubSub, get_session(socket), message)
    {:noreply, socket}
  end

  def handle_event("select-ticket", %{"ticketnumber" => ticket}, socket) do
    issue =
      socket.assigns.issues
      |> Enum.find(fn i -> i.identifier == ticket end)

    {:noreply, assign(socket, :current_ticket, issue.identifier)}
  end

  defp get_session(socket) do
    "session:" <> socket.assigns.session
  end

  def handle_info({:list_updated, %{"ids" => id_list}}, socket) do
    issues = socket.assigns.issues

    issues =
      for id <- id_list do
        Enum.find(issues, fn %{id: i_id} -> String.to_integer(id) == i_id end)
      end

    {:noreply, assign(socket, :issues, issues)}
  end
end
