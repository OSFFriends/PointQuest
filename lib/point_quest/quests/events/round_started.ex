defmodule PointQuest.Quests.Event.RoundStarted do
  @moduledoc """
  Update a quest to start a new round.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :quest_objective, :string
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  def changeset(round_started, params \\ %{}) do
    round_started
    |> cast(params, [:quest_id, :quest_objective])
    |> default_quest_objective()
  end

  def default_quest_objective(%Ecto.Changeset{valid?: false} = invalid_changeset),
    do: invalid_changeset

  def default_quest_objective(changeset) do
    if get_change(changeset, :quest_objective) != nil do
      changeset
    else
      put_change(changeset, :quest_objective, "")
    end
  end
end
