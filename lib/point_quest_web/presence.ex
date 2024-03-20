defmodule PointQuestWeb.Presence do
  use Phoenix.Presence, otp_app: :point_quest, pubsub_server: PointQuestWeb.PubSub
end
