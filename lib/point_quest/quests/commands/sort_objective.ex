defmodule PointQuest.Quests.Commands.SortObjective do
  @moduledoc """
  Updates the sort order for a single objective in a quest.
  """
  use PointQuest.Valuable

  alias PointQuest.Behaviour.Quests.Repo, as: QuestRepo
  alias PointQuest.Quests

  require PointQuest.Quests.Telemetry
  require Telemetrex

  @type t :: %__MODULE__{
          quest_id: String.t(),
          objective_id: String.t(),
          sort_order: float()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :objective_id, :string
    field :sort_order, :float
  end

  @spec execute(t(), PointQuest.Authentication.Actor.t()) ::
          {:ok, PointQuest.Quests.Event.ObjectiveSorted.t()}
  def execute(%__MODULE__{quest_id: quest_id} = sort_objective_command, actor) do
    Telemetrex.span event: Quests.Telemetry.objective_sorted(),
                    context: %{command: sort_objective_command, actor: actor} do
      with {:ok, quest} <- QuestRepo.get_quest_by_id(quest_id),
           true <- can_sort?(quest, actor),
           {:ok, event} <- Quests.Quest.handle(sort_objective_command, quest) do
        QuestRepo.write(quest, event)
      else
        false -> {:error, :must_be_leader_of_party}
        {:error, _error} = error -> error
      end
    after
      {:ok, event} -> %{event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end

  defp can_sort?(quest, actor) do
    [
      Quests.Spec.is_party_leader?(quest, actor)
    ]
    |> Enum.all?()
  end
end
