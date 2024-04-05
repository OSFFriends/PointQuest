defmodule PointQuestWeb.QuestLive do
  @moduledoc """
  Page where we're actually running the quest.
  """
  use PointQuestWeb, :live_view

  alias PointQuest.Authentication.Actor.PartyLeader
  alias PointQuest.Error
  alias PointQuest.Quests.Commands
  alias PointQuest.Quests.Event
  alias PointQuestWeb.Live.Components

  require Logger

  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full">
      <div :if={is_party_leader?(@actor)} id="leader-controls" class="flex justify-between">
        <div id="quest-actions">
          <.button :if={!@round_active?} phx-click="start_round">New round</.button>
          <.button :if={@round_active?} phx-click="stop_round">Show Attacks</.button>
        </div>
        <div id="meta-actions" class="justify-end">
          <.button phx-click="copy_link">Copy Invite Link</.button>
        </div>
      </div>
      <div class="flex gap-4">
        <div :for={%{class: class, name: name} <- @adventurers} class="flex flex-col p-2">
          <div class={"#{get_background_color(name, @users)} rounded p-2"}>
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
        :if={show_attack_panel?(@actor, @round_active?)}
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
            form: nil,
            round_active?: quest.round_active?
          )
          |> handle_joins(PointQuestWeb.Presence.list(quest.id))

        {:error, :missing} ->
          redirect(socket, to: ~p"/quest/#{params["id"]}/join")

        {:error, %Error.NotFound{resource: :quest}} ->
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

  def handle_event("start_round", _params, socket) do
    %{actor: actor, quest: quest} = socket.assigns

    %{quest_id: quest.id}
    |> Commands.StartRound.new!()
    |> Commands.StartRound.execute(actor)

    {:ok, quest} = Infra.Quests.Db.get_quest_by_id(quest.id)

    {:noreply, assign(socket, quest: quest)}
  end

  def handle_event("stop_round", _params, socket) do
    %{actor: actor, quest: quest} = socket.assigns

    %{quest_id: quest.id}
    |> Commands.StopRound.new!()
    |> Commands.StopRound.execute(actor)

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

  def handle_info(%Event.RoundStarted{}, socket) do
    {
      :noreply,
      assign(socket, round_active?: true)
    }
  end

  def handle_info(%Event.RoundEnded{}, socket) do
    {
      :noreply,
      assign(socket, round_active?: false)
    }
  end

  def handle_joins(socket, joins) do
    {:ok, adventurers} = Infra.Quests.Db.get_all_adventurers(socket.assigns.quest.id)

    Enum.reduce(joins, socket, fn {user, %{metas: [meta | _]}}, socket ->
      meta = Map.put(meta, :connected?, true)
      assign(socket, users: Map.put(socket.assigns.users, user, meta), adventurers: adventurers)
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

  defp show_attack_panel?(%PartyLeader{adventurer: nil}, _round_active?), do: false
  defp show_attack_panel?(_actor, round_active?), do: round_active?

  defp get_background_color(name, users) do
    Enum.filter(users, fn {_id, u} -> u.name == name and u.connected? end)
    |> Enum.any?()
    |> if do
      ""
    else
      "bg-gray-400"
    end
  end
end
