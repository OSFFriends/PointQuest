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
  alias PointQuestWeb.QuestAudioLive

  require Logger

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-y-8 w-full">
      <.render_party_leader_controls
        round_active?={@round_active?}
        actor={@actor}
        quest_objective={@quest_objective}
      />
      <div class="flex justify-between">
        <div class={"#{if @round_active?, do: "visible", else: "invisible"} flex gap-x-2 items-center"}>
          <.icon name="hero-arrow-top-right-on-square" />
          <%= if @quest_objective != "" do %>
            <a href={@quest_objective} target="_blank" class="text-indigo-500">
              <%= @quest_objective %>
            </a>
          <% else %>
            N/A
          <% end %>
        </div>
        <%= live_render(@socket, QuestAudioLive,
          id: "quest-audio-bar",
          session: %{"quest_id" => @quest.id, "audio_preferences" => @audio_preferences}
        ) %>
      </div>
      <div class="flex gap-4 justify-center">
        <%!-- Adventurer --%>
        <div
          :for={%{id: id, class: class, name: name} <- @adventurers}
          class="flex flex-col items-center justify-between w-1/5"
        >
          <%!-- Attack --%>
          <.render_attack_choice reveal_attacks?={@reveal_attacks?} attack={Map.get(@attacks, id)} />
          <%!-- Sprite --%>
          <div class="w-16 mb-2">
            <img
              src={"/images/#{class}.png"}
              alt={"small sprite representing #{class} class"}
              class="w-full"
            />
          </div>
          <.render_health_bar connected?={
            Enum.find(@users, fn {_id, u} -> u.name == name and u.connected? end)
          } />
          <p class="text-bold"><%= name %></p>
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
    <.button phx-click="toggle-nerd-bar">
      <.icon name="hero-beaker" /> Toggle Nerd Stats
    </.button>
    <div :if={@show_nerd_bar?} class="bg-slate-300 mt-6">
      <p>Node: <%= Node.self() %></p>
      <p>Liveview: <%= inspect(self()) %></p>
      <p>
        Game: <%= inspect(
          GenServer.whereis({:via, Horde.Registry, {Infra.Quests.InMemory.Registry, @quest.id}})
        ) %>
      </p>
    </div>
    """
  end

  def render_party_leader_controls(%{round_active?: false} = assigns) do
    ~H"""
    <div :if={is_party_leader?(@actor)} id="leader-controls" class="flex justify-between items-center">
      <div class="flex justify-between items-center gap-x-4">
        <div id="quest-actions">
          <.button phx-click="start_round" class="flex items-center justify-around gap-x-2">
            <.icon name="hero-arrow-path" /> New round
          </.button>
        </div>
        <.form
          for={%{"quest_objective" => @quest_objective}}
          phx-change="validate_link"
          phx-submit="start_round"
        >
          <.input
            name={:quest_objective}
            value={@quest_objective}
            type="text"
            placeholder="Issue Link"
            class="mt-0"
          />
        </.form>
      </div>
      <div id="meta-actions">
        <.button phx-click="copy_link" class="flex items-center justify-around gap-x-2">
          <.icon name="hero-flag" /> Copy Invite Link
        </.button>
      </div>
    </div>
    """
  end

  def render_party_leader_controls(%{round_active?: true} = assigns) do
    ~H"""
    <div :if={is_party_leader?(@actor)} id="leader-controls" class="flex justify-between items-center">
      <div class="flex justify-between gap-x-4">
        <div id="quest-actions">
          <.button phx-click="stop_round" class="flex items-center justify-around gap-x-2">
            <.icon name="hero-eye" /> Show Attacks
          </.button>
        </div>
      </div>
      <div id="meta-actions">
        <.button phx-click="copy_link" class="flex items-center justify-around gap-x-2">
          <.icon name="hero-flag" /> Copy Invite Link
        </.button>
      </div>
    </div>
    """
  end

  def render_attack_choice(assigns) do
    ~H"""
    <div class={[
      "#{if @attack, do: "visible", else: "invisible"} relative flex justify-center items-center",
      "w-16 h-28 mb-8 bg-stone-300 border-2 border-stone-200 rounded-lg",
      "after:absolute after:w-[104%] after:h-[102%] after:top-[5px] after:left-0 after:bg-stone-400 after:-z-10 after:rounded-lg after:shadow-sm"
    ]}>
      <span :if={@reveal_attacks?} class="text-2xl text-stone-700"><%= @attack %></span>
    </div>
    """
  end

  def render_health_bar(assigns) do
    ~H"""
    <div class="flex rounded-lg items-start h-4 border-2 border-gray-600 w-24">
      <%= if @connected? do %>
        <div class="rounded-lg bg-green-400 w-full h-full"></div>
      <% else %>
        <div class="rounded-l-lg bg-red-400 w-1/4 h-full"></div>
      <% end %>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      case PointQuest.quest_repo().get_quest_by_id(params["id"]) do
        {:ok, quest} ->
          user_meta = actor_to_meta(socket.assigns.actor)
          PointQuestWeb.Presence.track(self(), quest.id, user_meta.user_id, user_meta)
          Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest.id)

          {:ok, adventurers} =
            PointQuest.quest_repo().get_all_adventurers(quest.id)

          attacks =
            Enum.reduce(quest.attacks, %{}, fn a, attacks ->
              Map.put(attacks, a.adventurer_id, a.attack)
            end)

          socket
          |> assign(
            quest: quest,
            users: %{},
            adventurers: adventurers,
            attacks: attacks,
            form: nil,
            round_active?: quest.round_active?,
            reveal_attacks?: not quest.round_active? and not Enum.empty?(attacks),
            quest_objective: quest.quest_objective,
            show_nerd_bar?: false
          )
          |> handle_joins(PointQuestWeb.Presence.list(quest.id))

        {:error, :missing} ->
          redirect(socket, to: ~p"/quest/#{params["id"]}/join")

        {:error, %Error.NotFound{resource: :quest}} ->
          redirect(socket, to: ~p"/quest")
      end

    {:ok, socket}
  end

  def handle_event("validate_link", %{"quest_objective" => link}, socket) do
    {:noreply, assign(socket, quest_objective: link)}
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

    params =
      if String.length(socket.assigns.quest_objective) > 0 do
        %{
          quest_id: quest.id,
          quest_objective: socket.assigns.quest_objective
        }
      else
        %{quest_id: quest.id}
      end

    params
    |> Commands.StartRound.new!()
    |> Commands.StartRound.execute(actor)

    {:ok, quest} = PointQuest.quest_repo().get_quest_by_id(quest.id)

    {:noreply, assign(socket, quest: quest)}
  end

  def handle_event("stop_round", _params, socket) do
    %{actor: actor, quest: quest} = socket.assigns

    %{quest_id: quest.id}
    |> Commands.StopRound.new!()
    |> Commands.StopRound.execute(actor)

    {:noreply, socket}
  end

  def handle_event("toggle-nerd-bar", _params, socket) do
    {:noreply, assign(socket, show_nerd_bar?: not socket.assigns.show_nerd_bar?)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  def handle_info(
        %Event.AdventurerAttacked{adventurer_id: adventurer_id, attack: attack_value},
        socket
      ) do
    attacks = Map.put(socket.assigns.attacks, adventurer_id, attack_value)

    socket =
      socket
      |> assign(attacks: attacks)
      |> push_event("play-sound", %{event: "attack"})

    {
      :noreply,
      socket
    }
  end

  def handle_info(%Event.RoundStarted{quest_objective: link}, socket) do
    {
      :noreply,
      assign(socket,
        round_active?: true,
        reveal_attacks?: false,
        attacks: %{},
        quest_objective: link
      )
    }
  end

  def handle_info(%Event.RoundEnded{}, socket) do
    {
      :noreply,
      assign(socket, round_active?: false, reveal_attacks?: true, quest_objective: "")
    }
  end

  def handle_joins(socket, joins) do
    {:ok, adventurers} = PointQuest.quest_repo().get_all_adventurers(socket.assigns.quest.id)

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
    %{user_id: user_id, class: "leader", name: "Party Leader", adventurer_id: nil}
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.PartyLeader{
         leader_id: user_id,
         adventurer: adventurer
       }) do
    %{
      user_id: user_id,
      class: adventurer.class,
      name: adventurer.name,
      adventurer_id: adventurer.id
    }
  end

  defp actor_to_meta(%PointQuest.Authentication.Actor.Adventurer{
         adventurer: %{id: user_id} = adventurer
       }) do
    %{
      user_id: user_id,
      class: adventurer.class,
      name: adventurer.name,
      adventurer_id: adventurer.id
    }
  end

  defp is_party_leader?(%PartyLeader{} = _actor), do: true
  defp is_party_leader?(_actor), do: false

  defp show_attack_panel?(%PartyLeader{adventurer: nil}, _round_active?), do: false
  defp show_attack_panel?(_actor, round_active?), do: round_active?
end
