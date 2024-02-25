defmodule PointQuest.Linear do
  @moduledoc """
  Interface module for the Linear resources
  """
  @behaviour PointQuest.Behaviour.Linear

  alias Infra.Linear.Records.Token
  alias PointQuest.QueryParser

  @spec repo() :: module()
  def repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Repo)

  @spec client() :: module()
  def client(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Linear.Client)

  @impl PointQuest.Behaviour.Linear
  def has_token?(email) do
    with %PointQuest.Accounts.User{} = user <- PointQuest.Accounts.get_user_by_email(email),
         %Token{} <- repo().get_token_for_user(user.id) do
      true
    else
      nil ->
        false
    end
  end

  @impl PointQuest.Behaviour.Linear
  def list_teams(user_id) do
    body = %{query: QueryParser.list_teams([])}

    {:ok, %Tesla.Env{body: %{"data" => %{"teams" => %{"nodes" => teams}}}}} =
      client().post(body, user_id)

    teams
  end

  @impl PointQuest.Behaviour.Linear
  def list_issues(team_id, user_id) do
    issues_snippet = QueryParser.issues_snippet_slim([])
    body = %{query: QueryParser.list_issues_for_team(id: team_id, issues_snippet: issues_snippet)}

    {:ok, %Tesla.Env{body: %{"data" => %{"team" => team}}}} =
      client().post(body, user_id)

    team = Infra.LinearObject.load(Infra.Linear.Records.Team, team)
    team.issues
  end

  @impl PointQuest.Behaviour.Linear
  def load_issue(issue_id, user_id) do
    body = %{query: QueryParser.load_issue(id: issue_id)}

    {:ok, %Tesla.Env{body: %{"data" => %{"issue" => issue}}}} =
      client().post(body, user_id)

    Infra.LinearObject.load(Infra.Linear.Records.Issue, issue)
  end

  @impl PointQuest.Behaviour.Linear
  def redeem_code(redirect_uri, code, user_id) do
    with token <- client().token_from_code(redirect_uri, code),
         insert_changeset <-
           Token.insert_changeset(%Token{}, %{
             user_id: user_id,
             token: token["access_token"],
             provider: "Linear"
           }),
         {:ok, %Token{}} <- repo().insert_token(insert_changeset) do
      :ok
    end
  end
end
