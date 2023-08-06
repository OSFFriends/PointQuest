defmodule PointQuest.Behaviour.Ticket do
  @moduledoc """
  Behaviour interface for Linear interactions 
  """

  @callback get_team_id(team_name :: String.t()) :: String.t()
  @callback list_teams() :: [Infra.Linear.Records.Team.t()]
  @callback list_team_issues(team_id :: String.t()) :: Infra.Linear.Records.Team.t()
end
