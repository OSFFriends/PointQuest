defmodule PointQuestWeb.QuestAudioLive do
  @moduledoc """
  LiveView to push audio events from quest events.
  """
  use PointQuestWeb, :live_view
  alias PointQuest.Behaviour.Quests.Repo, as: QuestRepo
  alias PointQuest.Quests.Event
  alias PointQuest.Quests.Event
  alias PointQuestWeb.Events, as: WebEvents

  def render(assigns) do
    ~H"""
    <audio-preferences />
    """
  end

  def mount(_params, session, socket) do
    Phoenix.PubSub.subscribe(PointQuestWeb.PubSub, session["quest_id"])

    {:ok, assign(socket, actor_id: session["actor_id"])}
  end

  def handle_info(%Event.AdventurerAttacked{}, socket) do
    {
      :noreply,
      push_event(socket, "play-sound", %{event: "attack"})
    }
  end

  def handle_info(%Event.RoundEnded{quest_id: quest_id}, socket) do
    # Check if every adventurer attacked and chose the same value
    with {:ok, quest} <- QuestRepo.get_quest_by_id(quest_id),
         # leader could also be an attacker so +1 is okay
         true <- length(quest.attacks) >= length(quest.party.adventurers),
         [_same_attack] <- Enum.uniq_by(quest.attacks, &Map.get(&1, :attack)) do
      {:noreply, push_event(socket, "play-sound", %{event: "win"})}
    else
      _not_a_win ->
        {:noreply, socket}
    end
  end

  def handle_info(
        %WebEvents.AdventurerAlerted{adventurer_id: adventurer_id},
        %{assigns: %{actor_id: adventurer_id}} = socket
      ) do
    {:noreply, push_event(socket, "play-sound", %{event: "alert"})}
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end
end
