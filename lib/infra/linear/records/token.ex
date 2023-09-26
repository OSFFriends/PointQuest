defmodule Infra.Linear.Records.Token do
  @moduledoc """
  Token information related to Linear's API
  """

  import Ecto.Changeset

  use Ecto.Schema

  @type t :: %__MODULE__{
          user_id: integer(),
          token: String.t(),
          expiration: DateTime.t(),
          provider: String.t()
        }

  @primary_key {:id, :integer, autogenerate: false}
  schema "tokens" do
    belongs_to :user, PointQuest.Accounts.User
    field :token, :string
    field :expiration, :utc_datetime
    field :provider, :string
  end

  @spec insert_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t(t())
  def insert_changeset(token, attrs \\ %{}) do
    token
    |> cast(attrs, [:token, :expiration, :provider, :user_id])
  end
end
