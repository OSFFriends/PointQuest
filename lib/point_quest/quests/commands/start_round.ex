defmodule PointQuest.Quests.Commands.StartRound do
  @moduledoc """
  Command to start a round for the current quest.

  Ensure that you're calling either `new/1` or `new!/1` followed by `execute/1` in order to
  update the quest.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests
  alias PointQuest.Authentication

  @type t :: %__MODULE__{
          quest_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
  end

  @spec new(map()) :: {:ok, t()}
  @doc """
  Creates a command to start a round on the current quest.

  Returns a response tuple with the command.
  """
  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  @spec new!(map()) :: t()
  @doc """
  Creates a command to start a round on the current quest.

  Returns the command.
  """
  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  @spec changeset(start_round :: t(), params :: map()) :: Ecto.Changeset.t(t())
  @doc """
  Creates a changeset from start_round and params.
  """
  def changeset(start_round, params \\ %{}) do
    start_round
    |> cast(params, [:quest_id])
    |> validate_required([:quest_id])
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  @spec execute(start_round_command :: t(), actor :: Authentication.PartyLeader.t()) ::
          {:ok, Quests.Event.RoundStarted.t()}
          | {:error, Error.NotFound.exception(resource: :quest)}
          | {:error, :must_be_leader_of_quest_party}
          | {:error, :round_already_active}
  @doc """
  Executes the command to start the round, given the command struct and an actor.

  Returns a result tuple.
  """
  def execute(%__MODULE__{} = start_round_command, actor) do
    with {:ok, quest} <- repo().get_quest_by_id(start_round_command.quest_id),
         true <- can_start_round?(quest, actor),
         {:ok, event} <- Quests.Quest.handle(start_round_command, quest),
         {:ok, _quest} <- repo().write(quest, event) do
      {:ok, event}
    else
      false -> {:error, :must_be_leader_of_quest_party}
      {:error, _error} = error -> error
    end
  end

  defp can_start_round?(quest, actor) do
    [Quests.Spec.is_party_leader?(quest, actor)]
    |> Enum.all?()
  end
end
