defmodule PointQuestWeb.Events.AdventurerAlerted do
  @moduledoc """
  Event for sending an alert to an adventurer.
  """
  use PointQuest.Valuable

  @type t :: %__MODULE__{
          adventurer_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :adventurer_id, :string
  end
end
