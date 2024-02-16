defmodule PointQuestWeb.Live.Components.List do
  use PointQuestWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <.header>
          <%= @list_name %>
        </.header>
        <div
          id="sortable-list"
          phx-hook="Sortable"
          class="mt-8 border rounded border-sky-100 shadow-sm"
          data-list_id="sortable-list"
        >
          <.live_component
            :for={item <- @list}
            id={item.id}
            module={PointQuestWeb.Live.Components.Ticket}
            item={item}
          />
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
