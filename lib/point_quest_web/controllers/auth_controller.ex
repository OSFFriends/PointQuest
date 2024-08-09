defmodule PointQuestWeb.AuthController do
  use PointQuestWeb, :controller
  alias Ueberauth.Strategy.Helpers
  alias PointQuest.Players

  plug Ueberauth

  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> clear_session()
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :github} = auth}} = conn, _params) do
    params = %{
      # NOTE: Try to get this into domain layer
      guild_id: Integer.to_string(auth.uid),
      guild_data: auth.extra.raw_info.user,
      guild: auth.provider
    }

    # get glyph
    {:ok, glyph} =
      params
      |> Players.Commands.EnsureGlyph.new!()
      |> Players.Commands.EnsureGlyph.execute([])

    # get player from glyph
    {:ok, player} =
      %{glyph: glyph}
      |> Players.Commands.GetPlayer.new!()
      |> Players.Commands.GetPlayer.execute([])

    # put on session
    dbg(glyph)
    dbg(player)

    # return conn
    conn
    |> redirect(to: "/")
  end
end
