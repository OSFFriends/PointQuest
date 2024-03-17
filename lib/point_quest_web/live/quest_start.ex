defmodule PointQuestWeb.QuestStartLive do
  @moduledoc """
  Retrieve and display quest information
  """
  use PointQuestWeb, :live_view

  alias PointQuest.Authentication
  alias PointQuest.Quests.Commands.StartQuest

  def render(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@form}
      id="start-quest-form"
      phx-submit="start_quest"
    >
      <.input id="quest_name" type="text" field={f[:name]} label="Quest Name" />
      <fieldset class="my-4">
        <legend class="py-2">Make your adventurer (if you want to also vote)</legend>
        <.inputs_for :let={adventurer_form} field={f[:party_leaders_adventurer]}>
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
      <.button type="submit">Start Quest</.button>
    </.form>
    """
  end

  #         class="flex justify-between text-left text-input-text px-2.5 py-2 text-sm bg-transparent border border-grey-300 rounded-md focus:outline-none focus:ring-0 peer"

  def mount(_params, _session, socket) do
    classes = PointQuest.Quests.Adventurer.Class.NameEnum.valid_atoms()

    start_quest = StartQuest.new!(%{})
    changeset = StartQuest.changeset(start_quest, %{})

    socket =
      assign(socket, start_quest: start_quest, classes: classes, form: to_form(changeset))

    {:ok, socket}
  end

  def handle_event(
        "start_quest",
        %{"start_quest" => %{"name" => quest_name, "party_leaders_adventurer" => adventurer}},
        socket
      ) do
    params =
      if Map.get(adventurer, "name") == "" do
        %{name: quest_name}
      else
        %{
          name: quest_name,
          party_leaders_adventurer: %{
            name: adventurer["name"],
            class: adventurer["class"]
          }
        }
      end

    {:ok, quest} =
      StartQuest.new!(params)
      |> StartQuest.execute()

    token =
      Authentication.create_actor(quest.party_leader)
      |> Authentication.actor_to_token()

    {:noreply, push_navigate(socket, to: ~p"/switch/#{token}")}
  end
end
