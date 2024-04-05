defmodule Infra.Quests.EventHandler do
  import PointQuest.Quests.Telemetry

  alias PointQuest.Authentication.Actor
  alias PointQuest.Quests.Event

  require Logger

  def attach() do
    :telemetry.attach_many(
      __MODULE__,
      [
        attack(:stop),
        round_started(:stop)
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
end
