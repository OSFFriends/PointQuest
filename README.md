# PointQuest

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Postgres Database

The default port for the postgres instance this app talks to has been moved to 5430. The docker-compose file does already reference this.

## Environment Setup

### Required Env Vars

This application requires an API key for the website https://linear.app to be stored
in the env var `LINEAR_API_KEY` at runtime.
