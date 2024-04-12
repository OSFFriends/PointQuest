defmodule PointQuestWeb.Middleware.LoadActor.Plug do
  @moduledoc """
  Attempts to load an actor from the Phoenix Session.
  """
  import Plug.Conn

  require Logger

  @spec init(keyword()) :: keyword()
  def init(config), do: config

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    Logger.info("Loading Actor from Phoenix Session")

    actor =
      with session_token when is_binary(session_token) <- get_session(conn, "session_token"),
           {:ok, actor} <- PointQuest.Authentication.token_to_actor(session_token) do
        actor
      else
        _no_session ->
          Logger.info("Unable to load Actor, continuing with no session")
          nil
      end

    assign(conn, :actor, actor)
  end
end

defmodule PointQuestWeb.Middleware.LoadActor.Hook do
  @moduledoc """
  Attempts to load an actor from the Phoenix Session prior to liveview's mount.
  """
  import Phoenix.Component
  require Logger

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {atom(), Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, phoenix_session, socket) do
    Logger.info("Loading Actor from Phoenix Session")

    actor =
      with session_token when is_binary(session_token) <- phoenix_session["session"],
           {:ok, actor} <- PointQuest.Authentication.token_to_actor(session_token) do
        actor
      else
        _no_session ->
          Logger.info("Unable to load Actor, continuing with no session")
          nil
      end

    {:cont, assign(socket, :actor, actor)}
  end
end
