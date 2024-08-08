defmodule PointQuestWeb.AuthController do
  use PointQuestWeb, :controller
  alias Ueberauth.Strategy.Helpers

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
    dbg(auth)

    %{
      external_provider_id: auth.uid,
      external_provider_raw: auth.extra.raw_info.user,
      provider: auth.provider
    }
    |> Players.Commands.EnsureGlyph.new!()
    |> Players.Commands.EnsureGlyph.execute()

    conn
    |> redirect(to: "/")
  end
end
