defmodule PointQuest.Quests.Commands.Attack do
  @moduledoc """
  Command for an adventure to attack for round in a quest.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Authentication.Actor
  alias PointQuest.Quests

  require PointQuest.Quests.Telemetry
  require Telemetrex

  @type t :: %__MODULE__{
          quest_id: String.t(),
          adventurer_id: String.t(),
          attack: Quests.AttackValue.t()
        }

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :adventurer_id, :string
    field :attack, Quests.AttackValue
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t(t())
  def changeset(attack, params \\ %{}) do
    attack
    |> cast(params, [:quest_id, :adventurer_id, :attack])
    |> validate_required([:quest_id, :adventurer_id, :attack])
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  def execute(%__MODULE__{quest_id: quest_id} = attack_command, actor) do
    Telemetrex.span event: Quests.Telemetry.attack(),
                    context: %{command: attack_command, actor: actor} do
      with {:ok, quest} <- repo().get_quest_by_id(quest_id),
           true <- can_attack?(attack_command, actor),
           {:ok, event} <- Quests.Quest.handle(attack_command, quest),
           {:ok, _quest} <- repo().write(quest, event) do
        {:ok, event}
      else
        false ->
          {:error, "attack disallowed"}

        {:error, _error} = error ->
          error
      end
    after
      {:ok, event} -> %{event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end

  defp can_attack?(command, actor) do
    [
      is_attacker?(command.adventurer_id, actor),
      is_in_party?(command.quest_id, actor)
    ]
    |> Enum.all?()
  end

  defp is_attacker?(_attacker_id, %Actor.PartyLeader{adventurer: nil}), do: false

  defp is_attacker?(attacker_id, %Actor.PartyLeader{adventurer: %{id: attacker_id}}), do: true

  defp is_attacker?(_attacker_id, %Actor.PartyLeader{adventurer: %{id: _other_adventurer}}),
    do: false

  defp is_attacker?(attacker_id, %Actor.Adventurer{adventurer: %{id: attacker_id}}), do: true

  defp is_attacker?(_attacker_id, %Actor.Adventurer{adventurer: %{id: _other_adventurer}}),
    do: false

  defp is_in_party?(_quest_id, %Actor.PartyLeader{adventurer: nil}), do: false

  defp is_in_party?(quest_id, %Actor.PartyLeader{quest_id: quest_id}), do: true
  defp is_in_party?(_quest_id, %Actor.PartyLeader{quest_id: _other_quest}), do: false

  defp is_in_party?(quest_id, %Actor.Adventurer{quest_id: quest_id}), do: true
  defp is_in_party?(_quest_id, %Actor.Adventurer{quest_id: _other_quest}), do: false
end
