defmodule PointQuest.Quests.GetAdventurer do
  @moduledoc """
  Gets an adventurer's details given a quest and adventurer id
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :adventurer_id, :string
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:get)
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:get)
  end

  defp changeset(get_adventurer, params) do
    get_adventurer
    |> cast(params, [:quest_id, :adventurer_id])
    |> validate_required([:quest_id, :adventurer_id])
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  def execute(%__MODULE__{quest_id: quest_id, adventurer_id: adventurer_id}) do
    repo().get_adventurer_by_id(quest_id, adventurer_id)
  end
end
