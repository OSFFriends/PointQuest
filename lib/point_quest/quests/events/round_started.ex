defmodule PointQuest.Quests.Event.RoundStarted do
  @moduledoc """
  Update a quest to start a new round.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :quest_id, :string
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  def changeset(round_started, params \\ %{}) do
    round_started
    |> cast(params, [:quest_id])
  end
end
