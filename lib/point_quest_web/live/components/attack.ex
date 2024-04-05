defmodule PointQuestWeb.Live.Components.Attack do
  use PointQuestWeb, :live_component

  alias PointQuest.Quests.Commands.Attack

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
    # Quests.AttackValue expects the attack to be an integer
    attack_value = params["attack"] |> String.to_integer()

    %{
      quest_id: socket.assigns.quest_id,
      adventurer_id: socket.assigns.actor.adventurer.id,
      attack: attack_value
    }
    |> Attack.new!()
    |> Attack.execute(socket.assigns.actor)

    socket = assign(socket, selected_attack: attack_value)

    {:noreply, socket}
  end

  defp get_background_color(attack, attack), do: "bg-amber-400 hover:bg-amber-500"
  defp get_background_color(_attack, _selected), do: "bg-indigo-400 hover:bg-indigo-500"
end
