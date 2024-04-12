defmodule PointQuest.Quests.Event.RoundEnded do
  @moduledoc """
  Updates a quest to end the current round.
  """
  use PointQuest.Valuable

  @primary_key false
  embedded_schema do
    field :quest_id, :string
  end
end
