defmodule PointQuestWeb.QuestLive do
  @moduledoc """
  Page where we're actually running the quest.
  """
  use PointQuestWeb, :live_view

  def render(%{live_action: :join} = assigns) do
    ~H"""
    <div>You're looking to join <%= @session_id %></div>
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <pre><code><%= Jason.encode!(Ecto.embedded_dump(@quest, :json), pretty: true) %></code></pre>
    </div>
    """
  end

  def mount(params, _session, socket) do
    {:ok, quest} = Infra.Quests.Db.get_quest_by_id(params["id"])
    {:ok, assign(socket, session_id: params["id"], quest: quest)}
  end
end
