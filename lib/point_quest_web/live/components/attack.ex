defmodule PointQuestWeb.Live.Components.Attack do
  use PointQuestWeb, :live_component

  alias PointQuest.Quests.Commands.Attack

  def render(assigns) do
    ~H"""
    <div class="flex flex-row justify-center pt-16 gap-x-12 flex-wrap">
      <button
        :for={attack <- @attack_list}
        type="action"
        phx-click="set_attack"
        phx-value-attack={attack}
        phx-target={@myself}
        class={[
          "mb-8 w-16 h-16 rotate-45",
          "border-2",
          get_background_color(attack, @selected_attack)
        ]}
      >
        <span class="inline-block -rotate-45 font-bold text-xl"><%= attack %></span>
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
    attack_value = params["attack"]

    {:ok, adventurerer_attacked} =
      %{
        quest_id: socket.assigns.quest_id,
        adventurer_id: socket.assigns.actor.adventurer.id,
        attack: attack_value
      }
      |> Attack.new!()
      |> Attack.execute(socket.assigns.actor)

    socket = assign(socket, selected_attack: adventurerer_attacked.attack)

    {:noreply, socket}
  end

  defp get_background_color(attack, attack),
    do: "bg-amber-400 hover:bg-amber-500 border-amber-500"

  defp get_background_color(_attack, _selected),
    do: "bg-indigo-400 hover:bg-indigo-500 border-indigo-500"
end
