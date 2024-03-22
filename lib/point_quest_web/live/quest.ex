defmodule PointQuestWeb.QuestLive do
  @moduledoc """
  Page where we're actually running the quest.
  """
  use PointQuestWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <pre><code><%= Jason.encode!(Ecto.embedded_dump(@quest, :json), pretty: true) %></code></pre>
    </div>
    <div class="flex gap-4">
      <div :for={{user_id, %{name: name, class: class}} <- @users} class="bg-blue-400">
        <%= user_id %>
        <%= name %>
        <%= class %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      case Infra.Quests.Db.get_quest_by_id(params["id"]) do
        {:ok, quest} ->
          user_meta = actor_to_meta(socket.assigns.current_actor)
          PointQuestWeb.Presence.track(self(), quest.id, user_meta.user_id, user_meta)
          Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest.id)

          socket
          |> assign(quest: quest, users: %{}, form: nil)
          |> handle_joins(PointQuestWeb.Presence.list(quest.id))

        {:error, :missing} ->
          redirect(socket, to: ~p"/quest/#{params["id"]}/join")

        {:error, :quest_not_found} ->
          redirect(socket, to: ~p"/quest")
      end

    {:ok, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  def handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      assign(socket, :users, Map.put(socket.assigns.users, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.PartyLeader{quest_id: quest_id, leader_id: user_id, adventurer: nil}) do
    %{user_id: user_id, class: "leader", name: "Party Leader"}
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.PartyLeader{leader_id: user_id, adventurer: adventurer}) do
    %{user_id: user_id, class: adventurer.class, name: adventurer.name}
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.Adventurer{adventurer: %{id: user_id} = adventurer}) do
    %{user_id: user_id, class: adventurer.class, name: adventurer.name}
  end
end
