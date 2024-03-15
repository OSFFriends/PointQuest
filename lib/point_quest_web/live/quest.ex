defmodule PointQuestWeb.Quest do
  @moduledoc """
  Retrieve and display quest information
  """
  use PointQuestWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-start gap-y-5">
      <button id="start quest" phx-click="start_quest">Start Quest</button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    session_id = "12242ljl"

    socket =
      assign(socket,
        session: session_id
      )

    {:ok, socket}
  end

  def handle_event("start_quest", _params, socket) do
    {:noreply, socket}
  end
end
