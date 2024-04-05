defmodule Infra.Quests.EventHandler do
  @moduledoc """
  Event handlers for the Quests telemetry context.
  """

  import PointQuest.Quests.Telemetry

  alias PointQuest.Quests.Event

  def attach() do
    :telemetry.attach_many(
      __MODULE__,
      [
        attack(:stop),
        round_started(:stop),
        round_ended(:stop)
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(
        attack(:stop),
        _measurements,
        %{event: %Event.AdventurerAttacked{} = adventurer_attacked, actor: _actor},
        _config
      ) do
    Phoenix.PubSub.broadcast(
      PointQuestWeb.PubSub,
      adventurer_attacked.quest_id,
      adventurer_attacked
    )
  end

  def handle_event(
        round_started(:stop),
        _measurements,
        %{event: %Event.RoundStarted{} = round_started, actor: _actor},
        _config
      ) do
    Phoenix.PubSub.broadcast(
      PointQuestWeb.PubSub,
      round_started.quest_id,
      round_started
    )
  end

  def handle_event(
        round_ended(:stop),
        _measurements,
        %{event: %Event.RoundEnded{} = round_ended, actor: _actor},
        _config
      ) do
    Phoenix.PubSub.broadcast(
      PointQuestWeb.PubSub,
      round_ended.quest_id,
      round_ended
    )
  end

  def handle_event(_unhandled, _measurements, _context, _config) do
    :ok
  end
end
