defmodule PointQuest.Repo do
  use Ecto.Repo,
    otp_app: :point_quest,
    adapter: Ecto.Adapters.Postgres
end
