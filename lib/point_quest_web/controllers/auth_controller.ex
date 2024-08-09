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
      guild_id: auth.uid,
      guild_data: auth.extra.raw_info.user,
      guild: auth.provider
    }

    # get glyph
    params
    |> Players.Commands.GetGlyph.new!()
    |> Players.Commands.GetGlyph.execute([])
    |> case do
      {:error, %PointQuest.Error.NotFound{resource: :glyph}} ->
        params
        |> Players.Commands.CreateGlyph.new!()
        |> Players.Commands.CreateGlyph.execute([])

      {:ok, glyph} ->
        glyph
    end

    # put on session

    # return conn
    conn
    |> redirect(to: "/")
  end
end
