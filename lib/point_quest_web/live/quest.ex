defmodule PointQuestWeb.QuestLive do
  @moduledoc """
  Page where we're actually running the quest.
  """
  use PointQuestWeb, :live_view

  alias PointQuest.Quests.Event
  alias PointQuest.Authentication.Actor.PartyLeader
  alias PointQuestWeb.Live.Components

  require Logger

  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full">
      <div :if={is_party_leader?(@actor)} id="leader-controls" class="flex justify-between">
        <div id="quest-actions">
          <.button phx-click="show_attacks">Show Attacks</.button>
          <.button phx-click="clear_attacks">Clear Attacks</.button>
        </div>
        <div id="meta-actions" class="justify-end">
          <.button phx-click="copy_link">Copy Invite Link</.button>
        </div>
      </div>
      <div class="flex gap-4">
        <div :for={%{id: id, class: class, name: name} <- @adventurers} class="flex flex-col p-2">
          <div class={"#{get_background_color(id, @users)} rounded p-2"}>
            <div id="class-sprite" class="w-16 mt-2">
              <img
                src={"/images/#{class}.png"}
                alt={"small sprite representing #{class} class"}
                class="w-full"
              />
            </div>
            <p><%= name %></p>
          </div>
        </div>
      </div>
      <.live_component
        :if={show_attack_panel?(@actor)}
        module={Components.Attack}
        id="attack_controls"
        actor={@actor}
        quest_id={@quest.id}
      />
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      case Infra.Quests.Db.get_quest_by_id(params["id"]) do
        {:ok, quest} ->
          user_meta = actor_to_meta(socket.assigns.actor)
          PointQuestWeb.Presence.track(self(), quest.id, user_meta.user_id, user_meta)
          Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest.id)

          {:ok, adventurers} = Infra.Quests.Db.get_all_adventurers(quest.id)

          socket
          |> assign(
            quest: quest,
            users: %{},
            adventurers: adventurers,
            form: nil
          )
          |> handle_joins(PointQuestWeb.Presence.list(quest.id))

        {:error, :missing} ->
          redirect(socket, to: ~p"/quest/#{params["id"]}/join")

        {:error, :quest_not_found} ->
          redirect(socket, to: ~p"/quest")
      end

    {:ok, socket}
  end

  def handle_event("copy_link", _params, socket) do
    quest_id = socket.assigns.quest.id

    link = "#{PointQuestWeb.Endpoint.url()}/quest/#{quest_id}/join"

    socket =
      socket
      |> push_event("copy", %{text: link})

    {:noreply, socket}
  end

  def handle_event("show_attacks", _params, socket) do
    Logger.info("show attacks is not implemented yet")
    {:noreply, socket}
  end

  def handle_event("clear_attacks", _params, socket) do
    Logger.info("clear attacks is not implemented yet")
    _quest_id = socket.assigns.quest.id

    {:noreply, socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  def handle_info(%Event.AdventurerAttacked{adventurer_id: adventurer_id, attack: attack}, socket) do
    {
      :noreply,
      put_flash(socket, :info, "Adventurer: #{adventurer_id} attacked with #{attack}")
    }
  end

  def handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      meta = Map.put(meta, :connected?, true)
      assign(socket, :users, Map.put(socket.assigns.users, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, %{metas: [meta | _]}}, socket ->
      meta = Map.put(meta, :connected?, false)

      assign(
        socket,
        :users,
        Map.update(socket.assigns.users, user, meta, fn curr ->
          Map.put(curr, :connected?, false)
        end)
      )
    end)
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.PartyLeader{
         leader_id: user_id,
         adventurer: nil
       }) do
    %{user_id: user_id, class: "leader", name: "Party Leader"}
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.PartyLeader{
         leader_id: user_id,
         adventurer: adventurer
       }) do
    %{user_id: user_id, class: adventurer.class, name: adventurer.name}
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.Adventurer{
         adventurer: %{id: user_id} = adventurer
       }) do
    %{user_id: user_id, class: adventurer.class, name: adventurer.name}
  end

  defp is_party_leader?(%PartyLeader{} = _actor), do: true
  defp is_party_leader?(_actor), do: false

  defp show_attack_panel?(%PartyLeader{adventurer: nil}), do: false
  defp show_attack_panel?(_actor), do: true

  defp get_background_color(adventurer_id, users) do
    case Map.get(users, adventurer_id) do
      nil ->
        "bg-gray-400"

      user ->
        if user.connected? do
          ""
        else
          "bg-gray-400"
        end
    end
  end
end
