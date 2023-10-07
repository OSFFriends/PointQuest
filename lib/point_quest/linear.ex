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
    with token <- client().token_from_code(redirect_uri, code),
         insert_changeset <-
           Token.insert_changeset(%Token{}, %{
             user_id: user_id,
             token: token["access_token"],
             expiration: DateTime.utc_now() |> Timex.shift(seconds: token["expires_in"]),
             provider: "Linear"
           }),
         %Token{} <- repo().insert_token(insert_changeset) do
      :ok
    end
  end
end
