defmodule PointQuest.Quests.Event.ObjectiveAdded do
  @moduledoc """
  Update a quest to add a new objective.
  """
  use PointQuest.Valuable

  alias PointQuest.Quests.Objectives.Objective

  embedded_schema do
    field :quest_id, :string
    embeds_many :objectives, Objective
  end
end
