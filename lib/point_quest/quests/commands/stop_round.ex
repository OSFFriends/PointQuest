defmodule PointQuest.Quests.Commands.StopRound do
  @moduledoc """
  Command to stop a round for the current quest.

  Ensure that you're calling either `new/1` or `new!/1` followed by execute in order to
  update the quest.
  """
  use PointQuest.Valuable

  alias PointQuest.Quests
  alias PointQuest.Authentication

  require PointQuest.Quests.Telemetry
  require Telemetrex

  @type t :: %__MODULE__{
          quest_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id
  end

  @spec execute(stop_round_command :: t(), actor :: Authentication.PartyLeader.t(), keyword()) ::
          {:ok, t()}
          | {:error, Error.NotFound.exception(resource: :quest)}
          | {:error, :must_be_leader_of_quest_party}
          | {:error, :round_not_active}
  @doc """
  Executes the command to stop the round.

  Returns the command.
  """
  def execute(%__MODULE__{} = stop_round_command, actor, opts \\ []) do
    Telemetrex.span event: Quests.Telemetry.round_ended(),
                    context: %{command: stop_round_command, actor: actor} do
      repo = Keyword.get(opts, :quest_repo, PointQuest.quest_repo())

      with {:ok, quest} <- repo.get_quest_by_id(stop_round_command.quest_id),
           true <- can_stop_round?(quest, actor),
           {:ok, event} <- Quests.Quest.handle(stop_round_command, quest) do
        repo.write(quest, event)
      else
        false -> {:error, :must_be_leader_of_quest_party}
        {:error, _error} = error -> error
      end
    after
      {:ok, event} -> %{event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end

  defp can_stop_round?(quest, actor) do
    [Quests.Spec.is_party_leader?(quest, actor)]
    |> Enum.all?()
  end
end
