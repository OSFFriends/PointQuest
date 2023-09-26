defmodule PointQuest.Behaviour.Linear.Repo do
  @moduledoc """
  behaviour for the Linear Repo module
  """
  @callback get_token_for_user(email :: String.t()) ::
              {:ok, String.t()} | {:error, :token_not_found}
end
