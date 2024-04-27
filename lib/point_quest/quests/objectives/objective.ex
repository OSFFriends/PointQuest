defmodule PointQuest.Quests.Objectives.Objective do
  @moduledoc """
  Object that all external issue types should map to.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import PointQuest.Macros.Enum

  defenum ObjectiveStatus, :status, ~w(incomplete active complete)a

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          status: ObjectiveStatus.t()
        }

  @primary_key false
  embedded_schema do
    field :id, :string
    field :title, :string
    field :description, :string
    field :status, ObjectiveStatus
  end

  def changeset(issue, params \\ %{}) do
    issue
    |> cast(params, [:id, :title, :description, :status])
    |> validate_required([:id])
    |> maybe_default_status()
  end

  defp maybe_default_status(changeset) do
    case get_change(changeset, :status) do
      nil ->
        put_change(changeset, :status, :incomplete)

      _status ->
        changeset
    end
  end
end
