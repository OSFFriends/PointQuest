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
      Hello <%= @session_id %>
      <div :if={@live_action == :join}>Look at you, joining a session</div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, session_id: params["id"])}
  end
end
