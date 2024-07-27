defmodule PointQuest.Quests.Commands.RemoveAdventurer do
  @moduledoc """
  Command to remove an adventurer from a quest.
  """
  use PointQuest.Valuable

  alias PointQuest.Authentication.Actor
  alias PointQuest.Quests

  require PointQuest.Quests.Telemetry
  require Telemetrex

  @type t :: %__MODULE__{
          adventurer_id: String.t(),
          quest_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :adventurer_id, :string
    field :quest_id, :string
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t(t())
  @doc """
  Creates a changeset from remove_adventurer struct and params.
  """
  def changeset(remove_adventurer, params) do
    remove_adventurer
    |> cast(params, [:adventurer_id, :quest_id])
    |> validate_required([:adventurer_id, :quest_id])
  end

  @spec execute(t(), Actor.t()) ::
          {:ok, PointQuest.Quests.Event.AdventurerRemovedFromParty.t()} | {:error, String.t()}
  @doc """
  Executes the command to update the quest state.

  Returns the event for removing an adventurer.
  """
  def execute(%__MODULE__{quest_id: quest_id} = remove_adventurer_command, actor) do
    Telemetrex.span event: Quests.Telemetry.remove_adventurer(),
                    context: %{command: remove_adventurer_command, actor: actor} do
      with {:ok, quest} <- PointQuest.quest_repo().get_quest_by_id(quest_id),
           {:ok, adventurer} <-
             PointQuest.quest_repo().get_adventurer_by_id(
               quest_id,
               remove_adventurer_command.adventurer_id
             ),
           true <- can_remove_adventurer?(adventurer, quest, actor),
           {:ok, event} <- Quests.Quest.handle(remove_adventurer_command, quest) do
        PointQuest.quest_repo().write(quest, event)
      else
        false ->
          {:error, "not authorized to remove adventurer"}
      end
    after
      {:ok, event} -> %{event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end

  defp can_remove_adventurer?(adventurer, quest, actor) do
    [
      Quests.Spec.actor_is_target?(adventurer, actor),
      Quests.Spec.is_in_party?(quest, actor),
      Quests.Spec.is_party_leader?(quest, actor)
    ]
    |> Enum.any?()
  end
end
