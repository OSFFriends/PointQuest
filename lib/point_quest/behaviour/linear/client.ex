defmodule PointQuest.Behaviour.Linear.Client do
  @moduledoc """
  Interface for abstracting linear client functionality
  """
  @callback token_from_code(redirect_uri :: String.t(), code :: String.t()) ::
              map() | {:ok, :code_already_redeemed} | {:error, :api_error}
end
