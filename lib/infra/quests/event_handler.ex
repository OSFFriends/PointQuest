defmodule Infra.Quests.EventHandler do
  import PointQuest.Quests.Telemetry
  alias PointQuest.Quests.Event

  def attach() do
    :telemetry.attach_many(
      __MODULE__,
      [
        attack(:stop)
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(
        attack(:stop),
        _measurements,
        %{event: %Event.AdventurerAttacked{} = adventurer_attacked},
        _config
      ) do
    Phoenix.PubSub.broadcast(
      PointQuestWeb.PubSub,
      adventurer_attacked.quest_id,
      adventurer_attacked
    )
  end
end
