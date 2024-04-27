defmodule PointQuest.Quests.Objectives.Objective do
  @moduledoc """
  Object that all external issue types should map to.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import PointQuest.Macros.Enum

  defenum ObjectiveStatus, :status, ~w(incomplete current complete)a

  @type t :: %__MODULE__{
          id: String.t(),
          identifier: String.t() | nil,
          title: String.t(),
          description: String.t() | nil,
          status: ObjectiveStatus.t(),
          sort_order: float()
        }

  @primary_key false
  embedded_schema do
    field :id, :string
    field :identifier, :string
    field :title, :string
    field :description, :string
    field :status, ObjectiveStatus
    field :sort_order, :float
  end

  def changeset(issue, params \\ %{}) do
    issue
    |> cast(params, [:id, :identifier, :title, :description, :status, :sort_order])
    |> validate_required([:title])
    |> maybe_new_id()
    |> maybe_default_status()
  end

  defp maybe_new_id(changeset) do
    if get_change(changeset, :id) do
      changeset
    else
      change(changeset, id: Nanoid.generate_non_secure())
    end
  end

  defp maybe_default_status(changeset) do
    if get_change(changeset, :status) do
      changeset
    else
      change(changeset, status: :incomplete)
    end
  end
end
