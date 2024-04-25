defmodule PointQuestWeb.Middleware.AudioPreferences.Hook do
  @moduledoc """
  Attempts to load an actor from the Phoenix Session prior to liveview's mount.
  """
  import Phoenix.Component
  import Phoenix.LiveView
  require Logger

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {atom(), Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, _phoenix_session, socket) do
    Logger.info("Loading users audio preferences")

    audio_preferences =
      case get_connect_params(socket) do
        %{"audio_preferences" => preferences} -> preferences
        _ -> false
      end

    {:cont, assign(socket, :audio_preferences, audio_preferences)}
  end
end
