defmodule PointQuest.Quests.Event.RoundEnded do
  @moduledoc """
  Updates a quest to end the current round.
  """
  use PointQuest.Valuable, optional_fields: [:objectives]

  alias PointQuest.Quests.Objectives.Objective

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    embeds_many :objectives, Objective
  end
end
