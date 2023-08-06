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
