defmodule Infra.Linear.Records.User do
  @moduledoc """
  A Linear user object.
  """

  use Infra.LinearObject

  @type t :: %__MODULE__{
          id: String.t(),
          avatarUrl: String.t(),
          displayName: String.t(),
          email: String.t(),
          url: String.t()
        }

  object do
    field :id, :string
    field :avatarUrl, :string
    field :displayName, :string
    field :email, :string
    field :url, :string
  end
end
