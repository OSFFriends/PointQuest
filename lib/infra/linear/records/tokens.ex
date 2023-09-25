defmodule Infra.Linear.Records.Tokens do
  @moduledoc """
  Token information related to Linear's API
  """

  use Infra.LinearObject

  @type tokens :: %__MODULE__{
          user: PointQuest.Accounts.User.t(),
          token: String.t(),
          expiration: DateTime.t(),
          provider: String.t()
        }

  object do
    embed(:user, PointQuest.Accounts.User)
    field :token, :string
    field :expiration, :utc_datetime
    field :provider, :string
  end
end
