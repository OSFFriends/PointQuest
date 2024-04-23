defmodule PointQuestWeb.QuestStartLive do
  @moduledoc """
  Retrieve and display quest information
  """
  use PointQuestWeb, :live_view

  alias PointQuest.Authentication
  alias PointQuest.Quests.Commands.StartQuest

  def render(assigns) do
    ~H"""
    <.form for={@form} class="flex flex-col space-y-6" id="start-quest-form" phx-submit="start_quest">
      <.input
        name={:join_as_adventurer}
        value={@join_as_adventurer}
        label="Join quest as an adventurer"
        type="checkbox"
        phx-click="toggle_join_as_adventurer"
      />
      <fieldset :if={@join_as_adventurer}>
        <.inputs_for :let={adventurer_form} field={@form[:party_leaders_adventurer]}>
          <.input
            id="adventurer_name"
            type="text"
            field={adventurer_form[:name]}
            label="Adventurer Name"
          />
          <.input
            id="adventurer_class"
            type="select"
            field={adventurer_form[:class]}
            label="Class"
            options={@classes}
          />
        </.inputs_for>
      </fieldset>
      <div>
        <.button type="submit" disabled={not @form.source.valid?}>Start Quest</.button>
      </div>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    classes = PointQuest.Quests.Adventurer.Class.NameEnum.valid_atoms()

    changeset = StartQuest.changeset(%StartQuest{}, %{})

    socket =
      assign(socket,
        classes: classes,
        form: to_form(changeset),
        join_as_adventurer: false
      )

    {:ok, socket}
  end

  def handle_event("toggle_join_as_adventurer", _params, socket) do
    {:noreply, assign(socket, join_as_adventurer: !socket.assigns.join_as_adventurer)}
  end

  def handle_event(
        "start_quest",
        %{
          "start_quest" => %{"party_leaders_adventurer" => adventurer},
          "join_as_adventurer" => "true"
        },
        socket
      ) do
    params =
      %{
        party_leaders_adventurer: %{
          name: adventurer["name"],
          class: adventurer["class"]
        }
      }

    {:ok, quest_started} =
      params
      |> StartQuest.new!()
      |> StartQuest.execute()
      |> dbg()

    {:ok, quest} = Infra.Quests.Db.get_quest_by_id(quest_started.quest_id)

    token =
      quest.party.party_leader
      |> Authentication.create_actor()
      |> Authentication.actor_to_token()

    {:noreply, push_navigate(socket, to: ~p"/switch/#{token}")}
  end

  def handle_event(
        "start_quest",
        %{"join_as_adventurer" => "false"},
        socket
      ) do
    {:ok, quest_started} =
      %{}
      |> StartQuest.new!()
      |> StartQuest.execute()

    {:ok, quest} = Infra.Quests.Db.get_quest_by_id(quest_started.quest_id)

    token =
      quest.party.party_leader
      |> Authentication.create_actor()
      |> Authentication.actor_to_token()

    {:noreply, push_navigate(socket, to: ~p"/switch/#{token}")}
  end
end
