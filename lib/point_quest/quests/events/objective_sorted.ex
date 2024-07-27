defmodule PointQuest.Quests.Event.ObjectiveSorted do
  @moduledoc """
  Event for when an objective has changed its sort order.
  """

  use PointQuest.Valuable

  alias PointQuest.Quests.Objectives.Objective

  @type t :: %__MODULE__{
          quest_id: String.t(),
          objectives: [Objective.t()]
        }

  embedded_schema do
    field :quest_id, :string
    embeds_many :objectives, Objective
  end
end
