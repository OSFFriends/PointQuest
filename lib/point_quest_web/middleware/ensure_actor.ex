defmodule PointQuestWeb.Middleware.EnsureActor.Plug do
  @moduledoc """
  Ensures that an actor is loaded, or else we redirect.
  """
  require Logger

  @spec init(keyword()) :: keyword()
  def init(config), do: config

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(%{assigns: %{actor: nil}} = conn, _opts) do
    Logger.warning("Actor is nil")
    # TODO: redirect if actor is not preset
    conn
  end

  def call(conn, _opts) do
    Logger.info("Ensured Actor is present")
    conn
  end
end

defmodule PointQuestWeb.Middleware.EnsureActor.Hook do
  @moduledoc """
  Ensures that an actor is loaded before liveview's mount is called.
  """
  import Phoenix.LiveView
  require Logger

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {atom(), Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, _phx_session, %{assigns: %{actor: nil}} = socket) do
    {:halt, redirect(socket, to: "/quest")}
  end

  def on_mount(:default, _params, _phx_session, socket) do
    {:cont, socket}
  end
end
