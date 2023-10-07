defmodule PointQuest.Linear do
  @moduledoc """
  Interface module for the Linear resources
  """
  alias Infra.Linear.Records.Team
  alias Infra.Linear.Records.Token
  alias PointQuest.QueryParser

  @spec repo() :: module()
  def repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Repo)
  def client(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Client)

  def has_token?(email) do
    with %PointQuest.Accounts.User{} = user <- PointQuest.Accounts.get_user_by_email(email),
         %Token{} <- repo().get_token_for_user(user.id) do
      true
    else
      nil ->
        false
    end
  end

  @spec list_teams(user_id :: String.t()) :: [map()]
  def list_teams(user_id) do
    body = %{query: QueryParser.list_teams([])}

    {:ok, %Tesla.Env{body: %{"data" => %{"teams" => %{"nodes" => teams}}}}} =
      client().post(body, user_id)

    teams
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
