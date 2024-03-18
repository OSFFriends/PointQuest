defmodule PointQuestWeb.QuestLive do
  @moduledoc """
  Page where we're actually running the quest.
  """
  use PointQuestWeb, :live_view

  alias PointQuest.Quests.Commands.AddAdventurer

  def render(%{live_action: :join} = assigns) do
    ~H"""
    <.form
      for={@form}
      id="join-quest-form"
      phx-change="validate_adventurer"
      phx-debounce="250"
      phx-submit="join_party"
    >
      <.input type="text" field={@form[:name]} label="Adventurer Name" />
      <.input type="select" field={@form[:class]} label="Class" options={@classes} />
      <.button type="submit" disabled={not @form.source.valid? |> dbg}>Join Quest</.button>
    </.form>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <pre><code><%= Jason.encode!(Ecto.embedded_dump(@quest, :json), pretty: true) %></code></pre>
    </div>
    """
  end

  def mount(params, _session, socket) do
    classes = PointQuest.Quests.Adventurer.Class.NameEnum.valid_atoms()

    changeset = get_changeset(%{quest_id: params["id"]})

    {:ok, quest} = Infra.Quests.Db.get_quest_by_id(params["id"])

    {:ok,
     assign(socket,
       session_id: params["id"],
       quest: quest,
       form: to_form(changeset),
       classes: classes
     )}
  end

  def handle_event("validate_adventurer", %{"add_adventurer" => params}, socket) do
    params = Map.put(params, "quest_id", socket.assigns.quest.id)

    form =
      get_changeset(params)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event(
        "join_party",
        %{"add_adventurer" => %{"name" => name, "class" => class}},
        socket
      ) do
    {:ok, quest} =
      AddAdventurer.new!(%{quest_id: socket.assigns.quest.id, name: name, class: class})
      |> AddAdventurer.execute()

    adventurer = Enum.find(quest.adventurers, fn a -> a.name == name end)

    token =
      PointQuest.Authentication.create_actor(adventurer)
      |> PointQuest.Authentication.actor_to_token()

    {:noreply, push_navigate(socket, to: ~p"/switch/#{token}")}
  end

  defp get_changeset(params) do
    case AddAdventurer.new(params) do
      {:ok, %AddAdventurer{} = command} -> AddAdventurer.changeset(command, %{})
      {:error, changeset} -> changeset
    end
  end
end
