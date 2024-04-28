defmodule PointQuestWeb.QuestJoinLive do
  use PointQuestWeb, :live_view

  alias PointQuest.Error
  alias PointQuest.Quests.Commands.GetAdventurer
  alias PointQuest.Quests.Commands.AddAdventurer
  alias PointQuest.Quests.Quest

  def render(assigns) do
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
      <.button type="submit" disabled={not @form.source.valid?}>Join Quest</.button>
    </.form>
    """
  end

  def mount(params, _session, socket) do
    socket =
      with {:ok, quest} <- PointQuest.quest_repo().get_quest_by_id(params["id"]),
           {:in_quest?, false} <- check_actor_in_quest(quest, socket.assigns.actor) do
        changeset = get_changeset(%{quest_id: quest.id})
        classes = PointQuest.Quests.Adventurer.Class.NameEnum.valid_atoms()

        socket
        |> assign(classes: classes, form: to_form(changeset), quest: quest)
      else
        {:in_quest?, true} ->
          redirect(socket, to: ~p"/quest/#{params["id"]}")

        {:error, %Error.NotFound{resource: :quest}} ->
          redirect(socket, to: ~p"/quest")
      end

    {:ok, socket}
  end

  def handle_event("validate_adventurer", %{"add_adventurer" => params}, socket) do
    params = Map.put(params, "quest_id", socket.assigns.quest.id)

    form =
      params
      |> get_changeset()
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event(
        "join_party",
        %{"add_adventurer" => %{"name" => name, "class" => class}},
        socket
      ) do
    {:ok, adventurer_added} =
      %{quest_id: socket.assigns.quest.id, name: name, class: class}
      |> AddAdventurer.new!()
      |> AddAdventurer.execute()

    {:ok, adventurer} =
      %{quest_id: socket.assigns.quest.id, adventurer_id: adventurer_added.adventurer_id}
      |> GetAdventurer.new!()
      |> GetAdventurer.execute()

    token =
      adventurer
      |> PointQuest.Authentication.create_actor()
      |> PointQuest.Authentication.actor_to_token()

    {:noreply, push_navigate(socket, to: ~p"/switch/#{token}")}
  end

  defp get_changeset(params) do
    case AddAdventurer.new(params) do
      {:ok, %AddAdventurer{} = command} -> AddAdventurer.changeset(command, %{})
      {:error, changeset} -> changeset
    end
  end

  def check_actor_in_quest(%Quest{id: quest_id}, %{quest_id: quest_id}) do
    {:in_quest?, true}
  end

  def check_actor_in_quest(_quest, _actor) do
    {:in_quest?, false}
  end
end
