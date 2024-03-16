defmodule PointQuestWeb.Switch do
  @moduledoc """
  Switches the session to the assigned quest
  """

  use PointQuestWeb, :controller
  # def home(conn, _params) do
  #   # The home page is often custom made,
  #   # so skip the default app layout.
  #   render(conn, :home, layout: false)
  # end

  def set_session(conn, %{"token" => token}) do
    # verify the session is valid
    with {:ok, session} <- PointQuest.Authentication.token_to_actor(token) do
      put_session(conn, :session, token)
      |> redirect(to: ~p"/quest/#{session.quest_id}")
    end
  end
end
