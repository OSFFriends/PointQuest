# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :point_quest, PointQuestWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PointQuestWeb.ErrorHTML, json: PointQuestWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PointQuestWeb.PubSub,
  live_view: [signing_salt: "Qx76kENh"]

# Configures dependency injection
# config :point_quest, PointQuest.Behaviour.Linear, PointQuest.Linear
# config :point_quest, PointQuest.Behaviour.Linear.Client, PointQuest.Linear.Client
# config :point_quest, PointQuest.Behaviour.Linear.Repo, PointQuest.Linear.Repo
config :point_quest, PointQuest.Behaviour.Players.Repo, Infra.Players.Couch.Db
config :point_quest, PointQuest.Behaviour.Quests, PointQuest.Quests
config :point_quest, PointQuest.Behaviour.Quests.Repo, Infra.Quests.Couch.Db
# config :point_quest, PointQuest.Behaviour.Ticket, Infra.Linear.Linear

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :point_quest, PointQuest.Mailer, adapter: Swoosh.Adapters.Local

config :point_quest, env: Mix.env()

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Nanoid
config :nanoid,
  size: 8,
  alphabet: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, []}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
