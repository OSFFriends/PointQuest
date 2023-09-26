defmodule PointQuest.Linear do
  @moduledoc """
  Interface module for the Linear resources
  """
  alias Infra.Linear.Records.Token

  @spec repo() :: module()
  def repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Repo)
  def client(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Client)

  def has_token?(email) do
    with %PointQuest.Accounts.User{} = user <- PointQuest.Accounts.get_user_by_email(email),
         %Token{} <- repo().get_token_for_user(user.id) do
      :ok
    else
      nil ->
        {:error, :token_not_found}
    end
  end

  def redeem_code(redirect_uri, code, user_id) do
    token = client().token_from_code(redirect_uri, code)
    {:ok, insert_changeset} = Token.insert_changeset(%Token{}, %{
      user_id: user_id, 
      token: token.token,
      expiration: token.expiration,
      provider: "Linear"
    })
    repo().insert_token(insert_changeset)
  end
end
