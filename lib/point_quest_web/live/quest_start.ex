defmodule PointQuestWeb.QuestStartLive do
  @moduledoc """
  Retrieve and display quest information
  """
  use PointQuestWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-start gap-y-5">
      <button id="start quest" phx-click="start_quest">Start Quest</button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    session_id = "12242ljl"

    socket =
      assign(socket,
        session_id: session_id
      )

    {:ok, socket}
  end

  def handle_event("start_quest", _params, socket) do
    {:ok, quest} =
      PointQuest.Quests.StartQuest.new!(%{name: "can't believe this works"})
      |> PointQuest.Quests.StartQuest.execute()

    token =
      PointQuest.Authentication.create_actor(quest.party_leader)
      |> PointQuest.Authentication.actor_to_token()

    {:noreply, push_navigate(socket, to: ~p"/switch/#{token}")}
  end
end
