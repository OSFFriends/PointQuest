defmodule PointQuestWeb.Live.Components.Objective do
  @moduledoc """
  A component for displaying an objective.

  Controls the visual representation in our LiveViews for
  `PointQuest.Quest.Objectives.Objective`
  """
  use PointQuestWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      class="px-2 py-8 mb-2 bg-white rounded-lg"
      phx-click="select-objective"
      phx-value-objective_id={@objective.title}
    >
      <%= @objective.title %>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
