defmodule PointQuest.Quests.Commands.Attack do
  @moduledoc """
  Command for an adventure to attack for round in a quest.
  """
  use PointQuest.Valuable

  alias PointQuest.Quests
  alias PointQuest.Quests.Commands

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

  def execute(%__MODULE__{quest_id: quest_id} = attack_command, actor) do
    Telemetrex.span event: Quests.Telemetry.attack(),
                    context: %{command: attack_command, actor: actor} do
      with {:ok, quest} <- repo().get_quest_by_id(quest_id),
           {:ok, adventurer} <-
             Commands.GetAdventurer.execute(
               Commands.GetAdventurer.new!(%{
                 quest_id: quest.id,
                 adventurer_id: attack_command.adventurer_id
               })
             ),
           true <- can_attack?(adventurer, quest, actor),
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

  defp can_attack?(adventurer, quest, actor) do
    [
      Quests.Spec.is_attacker?(adventurer, actor),
      Quests.Spec.is_in_party?(quest, actor)
    ]
    |> Enum.all?()
  end
end
