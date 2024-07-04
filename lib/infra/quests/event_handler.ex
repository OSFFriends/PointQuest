defmodule Infra.Quests.EventHandler do
  @moduledoc """
  Event handlers for the Quests telemetry context.
  """

  import PointQuest.Quests.Telemetry

  def attach() do
    :telemetry.attach_many(
      __MODULE__,
      [
        attack(:stop),
        add_objective(:stop),
        objective_sorted(:stop),
        remove_adventurer(:stop),
        round_started(:stop),
        round_ended(:stop)
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(
        _event,
        _measurements,
        %{event: event, actor: _actor},
        _config
      ) do
    Phoenix.PubSub.broadcast(PointQuestWeb.PubSub, event.quest_id, event)
  end

  def handle_event(_unhandled, _measurements, _context, _config) do
    :ok
  end
end
