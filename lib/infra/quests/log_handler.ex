defmodule Infra.Quests.LogHandler do
  import PointQuest.Quests.Telemetry

  alias PointQuest.Authentication.Actor
  alias PointQuest.Quests.Event

  require Logger

  def attach() do
    :telemetry.attach_many(
      __MODULE__,
      [
        attack(:stop),
        quest_started(:stop),
        round_ended(:stop)
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(
        quest_started(:stop),
        _measurements,
        %{event: %Event.QuestStarted{} = quest_started},
        _config
      ) do
    Logger.info(~s/Quest "#{quest_started.name}" started with id: #{quest_started.quest_id}/)
  end

  def handle_event(
        quest_started(:stop),
        _measurements,
        %{command: start_quest, error: true, reason: reason},
        _config
      ) do
    Logger.info(~s/Quest "#{start_quest.name}" failed to start - #{inspect(reason)}/)
  end

  def handle_event(
        attack(:stop),
        _measurements,
        %{error: true, actor: actor, command: command, reason: reason},
        _config
      ) do
    Logger.error(
      "Adventurer #{Actor.get_actor_id(actor)} failed to attack in quest #{command.quest_id}: #{inspect(reason)}"
    )
  end

  def handle_event(
        round_ended(:stop),
        _measurements,
        %{error: true, reason: reason, actor: actor, command: command},
        _config
      ) do
    Logger.error(
      "Failed to stop round - #{inspect(reason)}. actor: #{inspect(actor)}, command: #{inspect(command)}"
    )
  end

  def handle_event(_unhandled, _measurements, _context, _config) do
    Logger.error("tee hee")
    :ok
  end
end
