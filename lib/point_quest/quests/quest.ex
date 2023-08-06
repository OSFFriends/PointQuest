defmodule PointQuest.Quests.Quest do
  @moduledoc """
  Object for holding the current voting context
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias PointQuest.Quests.Adventurer
  alias PointQuest.Quests.Attack

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    embeds_many :adventurers, Adventurer
    embeds_many :attacks, Attack
    embeds_one :party_leader, Adventurer
    field :name, :string
    field :lead_from_the_front, :boolean
    field :all_adventurers_attacking?, :boolean
  end

  def create_changeset(quest, params \\ %{}) do
    quest
    |> change(all_adventurers_attacking?: false)
    |> cast(params, [:name, :lead_from_the_front])
    |> validate_required([:name])
    |> cast_embed(:party_leader, with: &Adventurer.create_changeset/2, required: true)
    |> handle_party_leader_as_adventurer()
  end

  def add_adventurer_to_party_changeset(quest, adventurer_parms \\ %{}) do
    with %Ecto.Changeset{valid?: true} = adventurer_changeset <-
           Adventurer.create_changeset(%Adventurer{}, adventurer_parms) do
      if can_add_to_party?(quest, Ecto.Changeset.apply_changes(adventurer_changeset)) do
        current_adventurers = quest.adventurers

        change(quest, all_adventurers_attacking?: false)
        |> put_embed(:adventurers, [adventurer_changeset | current_adventurers])
      else
        change(quest)
        |> add_error(:adventurers, "Adventurer with that name is already on this quest")
      end
    end
  end

  def add_attack_changeset(quest, attack_params \\ %{}) do
    with %Ecto.Changeset{valid?: true} = attack_changeset <-
           Attack.create_changeset(%Attack{}, attack_params),
         adventurer <- Ecto.Changeset.apply_changes(attack_changeset).adventurer do
      current_attacks = quest.attacks

      if can_attack?(quest, adventurer) do
        quest_change =
          if all_adventurers_attacking?(quest) do
            change(quest, all_adventurers_attacking?: true)
          else
            change(quest, all_adventurers_attacking?: false)
          end

        quest_change
        |> put_embed(quest, :attacks, [attack_changeset | current_attacks])
      else
        change(quest)
        |> add_error(:attacks, "The adventurer must be part of the party before attacking")
      end
    end
  end

  defp all_adventurers_attacking?(quest) do
    length(quest.adventurers) == length(quest.attacks)
  end

  defp can_add_to_party?(quest, adventurer) do
    not Enum.any?(quest.adventurers, fn a -> a.name == adventurer.name end)
  end

  defp can_attack?(quest, adventurer) do
    Enum.any?(quest.adventurers, fn a -> a.name == adventurer end)
  end

  defp handle_party_leader_as_adventurer(quest) do
    if get_change(quest, :lead_from_the_front) do
      put_embed(quest, :adventurers, [get_change(quest, :party_leader)])
    else
      put_change(quest, :lead_from_the_front, false)
    end
  end

  defp can_add_to_party?(quest, adventurer) do
    not Enum.any?(quest.adventurers, fn a -> a.name == adventurer.name end)
  end
end
