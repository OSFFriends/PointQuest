defmodule PointQuest.Quests.Event.RoundEnded do
  @moduledoc """
  Updates a quest to end the current round.
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

  def changeset(round_ended, params \\ %{}) do
    round_ended
    |> cast(params, [:quest_id])
  end
end
