defmodule PointQuest.Quests.Event.RoundStarted do
  @moduledoc """
  Update a quest to start a new round.
  """
  use PointQuest.Valuable, optional_fields: [:objectives]

  alias PointQuest.Quests.Objectives.Objective

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    embeds_many :objectives, Objective
  end
end
