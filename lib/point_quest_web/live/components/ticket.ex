defmodule PointQuestWeb.Live.Components.Ticket do
  use PointQuestWeb, :live_component

  def render(assigns) do
    ~H"""
    <div id={"#{@item.id}"} class="px-2 py-8 my-2 border-b bg-white border-sky-100" data-id={@item.id}>
      <%= @item.identifier %> - <%= @item.title %>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
