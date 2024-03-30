defmodule PointQuestWeb.Middleware.QuestForwarder.Plug do
  use PointQuestWeb, :controller

  @spec init(any()) :: any()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _opts) do
    redirect(conn, to: ~p"/quest")
  end
end
