defmodule PointQuest.Behaviour.Quest do
  @moduledoc """
  Behaviour interface for quests
  """
  alias PointQuest.Quests.Quest

  @callback create(quest_params :: map()) :: Quest.t()
  @callback add_adventurer_to_party(quest_id :: String.t(), adventurer_params :: map()) ::
              {:ok, Quest.t()}
end
