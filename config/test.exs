import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :point_quest, PointQuestWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "NSik0XTnIRg5eOWsWCHiqI2WMSFVFAdwlCKIvTGqB+nQX5AfhAKfahQ7wCLf46+X",
  server: false

# Configures dependency injection
config :point_quest, PointQuest.Behaviour.Quests.Repo, Infra.Quests.SimpleInMemory.Db

# In test we don't send emails.
config :point_quest, PointQuest.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
