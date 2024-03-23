defmodule PointQuestWeb.Router do
  use PointQuestWeb, :router

  import Phoenix.LiveDashboard.Router
  import PointQuestWeb.LinearAuthPlug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PointQuestWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :try_load_actor do
    plug PointQuestWeb.Middleware.LoadActor.Plug
  end

  pipeline :linear_auth do
    plug :handle_linear_code
    plug :require_linear_token
  end

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: PointQuestWeb.Telemetry
  end

  live_session :ensure_actor, on_mount: [PointQuestWeb.Middleware.LoadActor.Hook] do
    pipe_through [:browser]

    scope "/", PointQuestWeb do
      get "/switch/:token", Switch, :set_session
      live "/quest/:id", QuestLive

      live "/quest", QuestStartLive
      live "/quest/:id/join", QuestJoinLive
    end
  end
end
