defmodule PointQuestWeb.Live.Components.Attack do
  use PointQuestWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="flex flex-row rounded-full pt-2">
      <button
        :for={attack <- @attack_list}
        type="action"
        phx-click="set_attack"
        phx-value-attack={attack}
        phx-target={@myself}
        class={[
          "p-4 first:rounded-s-full last:rounded-e-full",
          get_background_color(attack, @selected_attack)
        ]}
      >
        <%= attack %>
      </button>
    </div>
    """
  end

  def mount(socket) do
    attack_list = PointQuest.Quests.AttackValue.valid_attacks()

    {:ok, assign(socket, attack_list: attack_list, selected_attack: nil)}
  end

  def handle_event("set_attack", params, socket) do
    attack_value = params["attack"] |> String.to_integer()

    socket =
      case socket.assigns.selected_attack do
        ^attack_value -> assign(socket, selected_attack: nil)
        _else -> assign(socket, selected_attack: attack_value)
      end

    {:noreply, socket}
  end

  defp get_background_color(attack, attack), do: "bg-amber-400 hover:bg-amber-500"
  defp get_background_color(_attack, _selected), do: "bg-indigo-400 hover:bg-indigo-500"
end
