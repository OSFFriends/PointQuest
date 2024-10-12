defmodule PointQuestWeb.QuestLive do
  @moduledoc """
  Page where we're actually running the quest.
  """
  use PointQuestWeb, :live_view

  alias PointQuest.Authentication.Actor
  alias PointQuest.Authentication.Actor.PartyLeader
  alias PointQuest.Behaviour.Quests.Repo, as: QuestRepo
  alias PointQuest.Error
  alias PointQuest.Quests.Commands
  alias PointQuest.Quests.Event
  alias PointQuestWeb.Events, as: WebEvents
  alias PointQuestWeb.Live.Components
  alias PointQuestWeb.QuestAudioLive

  require Logger

  def render(assigns) do
    ~H"""
    <div id="top-level-wrapper" class="w-full flex mb-5">
      <!-- Objective sidebar -->
      <div :if={is_party_leader?(@actor)} id="objectives" class="w-1/5 mr-5">
        <div class="pb-5 w-full">
          <div id="sortable-list" phx-hook="Sortable" class="shadow-sm">
            <div
              :for={
                objective <-
                  @objectives
                  |> Enum.filter(&(&1.status != :complete))
                  |> Enum.sort_by(& &1.sort_order)
              }
              id={objective.id}
              phx-click="select-objective"
              phx-value-objective_id={objective.title}
              class={["p-2 mb-2 rounded-lg", get_objective_background(objective)]}
            >
              <%= objective.title %>
            </div>
          </div>
          <div
            phx-click={show_modal("add-objective")}
            class="flex justify-between p-2 mb-5 bg-white rounded-lg"
          >
            <p>New Objective</p>
            <.icon name="hero-plus-circle" class="bg-green-400 self-center" />
          </div>
          <div>
            <div phx-click="expand-completed" class="flex justify-between w-full bg-white rounded">
              <p class="p-3">Completed</p>
              <.icon
                :if={not @show_completed_objectives?}
                name="hero-chevron-down"
                class="self-center mr-2"
              />
              <.icon
                :if={@show_completed_objectives?}
                name="hero-chevron-up"
                class="self-center mr-2"
              />
            </div>
            <div :if={@show_completed_objectives?} id="completed-objectives" class="bg-gray-300">
              <div
                :for={objective <- @objectives |> Enum.filter(&(&1.status == :complete))}
                id={objective.id}
                class="p-2 mb-2 border-2 border-gray-400 rounded-lg"
              >
                <%= objective.title %>
              </div>
            </div>
          </div>
        </div>
      </div>
      <!-- Objective sidebar end -->
      <div id="quest-view" class="w-4/5">
        <div class="flex flex-col gap-y-8">
          <.render_party_leader_controls
            round_active?={@round_active?}
            actor={@actor}
            quest_objective={@quest_objective}
          />
          <div class="flex justify-between">
            <div class="flex gap-x-2 items-center">
              <.icon name="hero-arrow-top-right-on-square" />
              <a href={@quest_objective} target="_blank" class="text-indigo-500">
                <%= @quest_objective %>
              </a>
            </div>
            <%= live_render(@socket, QuestAudioLive,
              id: "quest-audio-preferences",
              session: %{"quest_id" => @quest.id, "actor_id" => Actor.get_actor_id(@actor)}
            ) %>
          </div>
          <div class="flex gap-4 justify-center">
            <%!-- Adventurer --%>
            <div
              :for={%{id: id, class: class, name: name} <- @adventurers}
              class="adventurer flex flex-col items-center justify-between w-1/5 relative"
            >
              <%!-- Attack --%>
              <.render_attack_choice
                reveal_attacks?={@reveal_attacks?}
                attack={Map.get(@attacks, id)}
              />
              <%!-- Kick adventurer --%>
              <div :if={is_party_leader?(@actor)} class="icon-container w-24 text-right">
                <a class="cursor-pointer" phx-click="kick-adventurer" phx-value-adventurer-id={id}>
                  <.icon name="hero-x-circle" class="icon text-red-500" />
                </a>
              </div>
              <%!-- Sprite --%>
              <div class="sprite-container w-16 mb-2" data-is-party-leader={is_party_leader?(@actor)}>
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
              <div :if={is_party_leader?(@actor)} class="icon-container flex items-start">
                <a
                  phx-click="alert-adventurer"
                  phx-value-adventurer-id={id}
                  phx-value-adventurer-name={name}
                  class="items-center cursor-pointer"
                >
                  <.icon name="hero-signal" class="icon" />
                </a>
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
      </div>
    </div>
    <.button phx-click="toggle-nerd-bar">
      <.icon name="hero-beaker" /> Toggle Nerd Stats
    </.button>
    <div :if={@show_nerd_bar?} class="bg-slate-300 mt-6 p-6">
      <p>Node: <%= Node.self() %></p>
      <p>Liveview: <%= inspect(self()) %></p>
      <p>
        Game: <%= inspect(
          GenServer.whereis({:via, Horde.Registry, {Infra.Quests.Couch.Registry, @quest.id}})
        ) %>
      </p>
      <header class="mt-6 mb-4">
        <span class="text-xl underline font-bold">Event Feed</span> - <span>Newest on top</span>
      </header>
      <div id="nerd-bar-event-stream" phx-update="stream">
        <div :for={{dom_id, event} <- @streams.events} class="mb-4" id={dom_id}>
          <code>
            <%= inspect(event) %>
          </code>
        </div>
      </div>
    </div>
    <.modal id="add-objective">
      <.form
        for={@add_objective_form}
        phx-change="validate-objective"
        phx-submit="add-objective"
        class="flex gap-5 justify-between"
      >
        <div class="flex gap-2">
          <p class="self-center">Objective</p>
          <.input
            type="text"
            id="new_quest_objective"
            field={@add_objective_form[:quest_objective]}
            class="w-full"
          />
        </div>
        <div>
          <.button type="submit">
            Add Objective
          </.button>
        </div>
      </.form>
    </.modal>
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
      case QuestRepo.get_quest_by_id(params["id"]) do
        {:ok, quest} ->
          user_meta = actor_to_meta(socket.assigns.actor)
          PointQuestWeb.Presence.track(self(), quest.id, user_meta.user_id, user_meta)
          Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, quest.id)

          {:ok, adventurers} =
            QuestRepo.get_all_adventurers(quest.id)

          attacks =
            Enum.reduce(quest.attacks, %{}, fn a, attacks ->
              Map.put(attacks, a.adventurer_id, a.attack)
            end)

          add_objective_form =
            Commands.AddSimpleObjective.changeset(%Commands.AddSimpleObjective{}, %{
              quest_id: quest.id
            })
            |> to_form()

          socket
          |> assign(
            add_objective_form: add_objective_form,
            adventurers: adventurers,
            attacks: attacks,
            form: nil,
            modal_active?: false,
            objectives: quest.objectives,
            quest: quest,
            quest_objective: quest.quest_objective,
            reveal_attacks?: not quest.round_active? and not Enum.empty?(attacks),
            round_active?: quest.round_active?,
            show_completed_objectives?: false,
            show_nerd_bar?: false,
            users: %{}
          )
          |> handle_joins(PointQuestWeb.Presence.list(quest.id))
          |> stream(:events, [], at: 0, limit: 30)

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

    %{quest_id: quest.id}
    |> Commands.StartRound.new!()
    |> Commands.StartRound.execute(actor)

    {:ok, quest} = QuestRepo.get_quest_by_id(quest.id)

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

  def handle_event(
        "update-sorting",
        %{"old" => old_index, "new" => new_index},
        socket
      ) do
    objectives = socket.assigns.objectives |> Enum.sort_by(fn o -> o.sort_order end)
    ending_index = length(objectives) - 1
    updated_objective = Enum.at(objectives, old_index)

    sort_order =
      case new_index do
        0 ->
          hd(objectives).sort_order - 0.001

        ^ending_index ->
          List.last(objectives).sort_order + 0.001

        index ->
          floor = Enum.at(objectives, index - 1)
          ceiling = Enum.at(objectives, index)
          (floor.sort_order + ceiling.sort_order) / 2
      end

    Commands.SortObjective.new!(%{
      quest_id: socket.assigns.quest.id,
      objective_id: updated_objective.id,
      sort_order: sort_order
    })
    |> Commands.SortObjective.execute(socket.assigns.actor)

    {:noreply, socket}
  end

  def handle_event("select-objective", params, socket) do
    {:noreply, assign(socket, quest_objective: params["objective_id"])}
  end

  def handle_event("expand-completed", _params, socket) do
    {:noreply,
     assign(socket, show_completed_objectives?: not socket.assigns.show_completed_objectives?)}
  end

  def handle_event("validate-objective", %{"add_simple_objective" => params}, socket) do
    form =
      Commands.AddSimpleObjective.changeset(
        socket.assigns.add_objective_form.data,
        Map.put(params, "quest_id", socket.assigns.quest.id)
      )
      |> to_form()

    {:noreply, assign(socket, add_objective_form: form)}
  end

  def handle_event(
        "add-objective",
        %{"add_simple_objective" => %{"quest_objective" => quest_objective}},
        socket
      ) do
    Commands.AddSimpleObjective.new!(%{
      quest_id: socket.assigns.quest.id,
      quest_objective: quest_objective
    })
    |> Commands.AddSimpleObjective.execute(socket.assigns.actor)

    form =
      Commands.AddSimpleObjective.changeset(
        Map.delete(socket.assigns.add_objective_form.data, :quest_objective),
        %{}
      )
      |> to_form()

    {:noreply, assign(socket, add_objective_form: form, modal_active?: false)}
  end

  def handle_event(
        "alert-adventurer",
        %{"adventurer-id" => id, "adventurer-name" => name},
        socket
      ) do
    event = WebEvents.AdventurerAlerted.new!(%{adventurer_id: id})

    Phoenix.PubSub.broadcast(PointQuestWeb.PubSub, socket.assigns.quest.id, event)

    {:noreply, put_flash(socket, :info, "#{name} notified")}
  end

  def handle_event("kick-adventurer", %{"adventurer-id" => id}, socket) do
    Commands.RemoveAdventurer.new!(%{adventurer_id: id, quest_id: socket.assigns.quest.id})
    |> Commands.RemoveAdventurer.execute(socket.assigns.actor)

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

  def handle_info(
        %Event.AdventurerAttacked{adventurer_id: adventurer_id, attack: attack_value} = event,
        socket
      ) do
    attacks = Map.put(socket.assigns.attacks, adventurer_id, attack_value)

    socket =
      socket
      |> assign(attacks: attacks)
      |> handle_event_stream(event)

    {:noreply, socket}
  end

  # remove from quest if you were just booted
  def handle_info(
        %Event.AdventurerRemovedFromParty{adventurer_id: adventurer_id} = event,
        %{assigns: %{actor: %Actor.Adventurer{adventurer: %{id: adventurer_id}}}} = socket
      ) do
    socket =
      socket
      |> put_flash(:info, "your bitch ass was removed")
      |> handle_event_stream(event)
      |> push_navigate(to: "/quest")

    {:noreply, socket}
  end

  def handle_info(
        %Event.AdventurerRemovedFromParty{adventurer_id: adventurer_id} = event,
        %{assigns: %{actor: _not_removed_adventurer}} = socket
      ) do
    adventurers = Enum.reject(socket.assigns.adventurers, fn %{id: id} -> id == adventurer_id end)

    socket =
      socket
      |> assign(adventurers: adventurers)
      |> handle_kick(adventurer_id)
      |> handle_event_stream(event)

    {:noreply, socket}
  end

  def handle_info(%Event.RoundStarted{objectives: objectives} = event, socket) do
    link =
      case Enum.find(objectives, fn o -> o.status == :current end) do
        nil ->
          "n/a"

        objective ->
          objective.title
      end

    socket =
      socket
      |> assign(
        round_active?: true,
        reveal_attacks?: false,
        attacks: %{},
        objectives: objectives,
        quest_objective: link
      )
      |> handle_event_stream(event)

    {:noreply, socket}
  end

  def handle_info(%Event.RoundEnded{objectives: objectives} = event, socket) do
    socket =
      socket
      |> assign(round_active?: false, reveal_attacks?: true, objectives: objectives)
      |> handle_event_stream(event)

    {:noreply, socket}
  end

  def handle_info(%Event.ObjectiveAdded{objectives: objectives} = event, socket) do
    socket =
      socket
      |> assign(objectives: objectives)
      |> handle_event_stream(event)

    {:noreply, socket}
  end

  def handle_info(%Event.ObjectiveSorted{objectives: objectives} = event, socket) do
    socket =
      socket
      |> assign(objectives: objectives)
      |> handle_event_stream(event)

    {:noreply, socket}
  end

  def handle_info(event, socket) when is_struct(event) do
    {:noreply, handle_event_stream(socket, event)}
  end

  def handle_joins(socket, joins) do
    {:ok, adventurers} = QuestRepo.get_all_adventurers(socket.assigns.quest.id)

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

  defp handle_kick(socket, adventurer_id) do
    users = Map.delete(socket.assigns.users, adventurer_id)

    assign(socket, users: users)
  end

  def handle_event_stream(socket, event) do
    stream_insert(socket, :events, event, at: 0, limit: 30)
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

  defp get_objective_background(%{status: :incomplete}), do: ["bg-white"]
  defp get_objective_background(%{status: :current}), do: ["bg-green-200"]
end
