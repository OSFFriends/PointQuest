defmodule PointQuest.Quests.Commands.AddSimpleObjective do
  @moduledoc """
  Command for a party leader to add a simple objective to the quest.
  """
  use PointQuest.Valuable

  alias PointQuest.Quests
  alias PointQuest.Quests.Objectives.Objective

  require PointQuest.Quests.Telemetry
  require Telemetrex

  @type t :: %__MODULE__{
          quest_id: String.t(),
          quest_objective: String.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :quest_objective, :string
  end

  @spec execute(add_objective_command :: t(), actor :: Authentication.PartyLeader.t()) ::
          {:ok, Quests.Event.ObjectiveAdded.t()}
  def execute(add_objective_command, actor) do
    Telemetrex.span event: Quests.Telemetry.add_objective(),
                    context: %{command: add_objective_command, actor: actor} do
      with {:ok, quest} <-
             PointQuest.quest_repo().get_quest_by_id(add_objective_command.quest_id),
           true <- can_add_objective(quest, actor),
           {:ok, event} <- Quests.Quest.handle(add_objective_command, quest),
           {:ok, _quest} <- PointQuest.quest_repo().write(quest, event) do
        {:ok, event}
      else
        false -> {:error, :must_be_leader_of_party}
        {:error, _error} = error -> error
      end
    after
      {:ok, event} -> %{event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end

  defp can_add_objective(quest, actor) do
    [
      Quests.Spec.is_party_leader?(quest, actor)
    ]
    |> Enum.any?()
  end

  defimpl PointQuest.Quests.Objectives.Questable do
    def to_objective(add_objective_command) do
      Objective.changeset(%Objective{}, %{
        id: add_objective_command.quest_objective
      })
      |> Ecto.Changeset.apply_action!(:insert)
    end
  end
end
