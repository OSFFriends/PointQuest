defmodule PointQuest.Quests.Objectives.Objective do
  @moduledoc """
  Object that all external issue types should map to.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t() | nil,
          description: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :id, :string
    field :title, :string
    field :description, :string
  end

  def changeset(issue, params \\ %{}) do
    issue
    |> cast(params, [:id, :title, :description])
    |> validate_required([:id])
  end
end
