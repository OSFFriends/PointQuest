defmodule PointQuest.Behaviour.Linear do
  @moduledoc """
  Interface for Linear service functionality
  """

  @callback has_token?(email :: String.t()) :: boolean()

  @callback list_issues(team_id :: String.t(), user_id :: String.t()) :: [Issue.issue_card()]

  @callback list_teams(user_id :: String.t()) :: [map()]

  @callback load_issue(issue_id :: String.t(), user_id :: String.t()) :: Issue.full_issue()

  @callback redeem_code(redirect_uri :: String.t(), code :: String.t(), user_id :: String.t()) ::
              :ok
end
