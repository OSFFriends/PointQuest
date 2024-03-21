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
      <div :for={{user_id, _meta} <- @users} class="bg-blue-400">
        <%= user_id %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      case Infra.Quests.Db.get_quest_by_id(params["id"]) do
        {:ok, quest} ->
          current_user = get_actor_id(socket.assigns.current_actor)

          {:ok, _state} =
            PointQuestWeb.Presence.track(self(), quest.id, current_user, %{})

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

  defp get_actor_id(%PointQuest.Authentication.Actor.PartyLeader{leader_id: user_id}), do: user_id

  defp get_actor_id(%PointQuest.Authentication.Actor.Adventurer{adventurer: %{id: user_id}}),
    do: user_id
end
