defmodule PointQuestWeb.QuestAudioLive do
  use PointQuestWeb, :live_view
  alias PointQuest.Quests.Event

  def render(assigns) do
    ~H"""
    <.button phx-click="toggle_audio" class="flex items-center">
      <%= if @audio_preferences do %>
        <.icon name="hero-speaker-wave" />
      <% else %>
        <.icon name="hero-speaker-x-mark" />
      <% end %>
    </.button>
    """
  end

  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, session["quest_id"])

    {:ok, assign(socket, audio_preferences: session["audio_preferences"])}
  end

  def handle_event("toggle_audio", _params, socket) do
    new_socket =
      socket
      |> assign(audio_preferences: not socket.assigns.audio_preferences)
      |> push_event("toggle-audio", %{})

    {:noreply, new_socket}
  end

  def handle_info(%Event.AdventurerAttacked{}, socket) do
    {
      :noreply,
      push_event(socket, "play-sound", %{event: "attack"})
    }
  end

  def handle_info(%Event.RoundEnded{quest_id: quest_id}, socket) do
    # Check if every adventurer attacked and chose the same value
    with {:ok, quest} <- PointQuest.quest_repo().get_quest_by_id(quest_id),
         # leader could also be an attacker
         true <- length(quest.attacks) >= length(quest.party.adventurers),
         [_same_attack] <- Enum.uniq_by(quest.attacks, &Map.get(&1, :attack)) do
      {
        :noreply,
        push_event(socket, "play-sound", %{event: "win"})
      }
    else
      error ->
        dbg()
        {:noreply, socket}
    end
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end
end
