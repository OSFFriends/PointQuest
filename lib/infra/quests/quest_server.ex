defmodule Infra.Quests.QuestServer do
  @moduledoc """
  Agent to hold quest state
  """

  use GenServer, restart: :transient

  def start_link(opts) do
    opts =
      opts
      |> Keyword.take([:quest, :timeout])
      |> Keyword.put_new(:timeout, :timer.hours(1))
      |> Map.new()

    GenServer.start_link(__MODULE__, opts,
      name: {:via, Registry, {Infra.Quests.Registry, opts.quest.id}}
    )
  end

  def update(server, quest) do
    GenServer.call(server, {:update_quest, quest})
  end

  def get(server) do
    GenServer.call(server, {:fetch_quest})
  end

  def init(%{quest: _quest, timeout: timeout} = opts) do
    timeout_ref = schedule_cleanup(timeout)
    state = Map.put(opts, :timeout_ref, timeout_ref)

    {:ok, state}
  end

  def handle_call({:update_quest, quest}, _from, state) do
    :erlang.cancel_timer(state.timeout_ref)

    state = %{
      state
      | timeout_ref: schedule_cleanup(state.timeout),
        quest: quest
    }

    {:reply, :ok, state}
  end

  def handle_call({:fetch_quest}, _from, state) do
    {:reply, state.quest, state}
  end

  def handle_info(:kill, _state) do
    Process.exit(self(), :shutdown)
  end

  defp schedule_cleanup(timeout) do
    Process.send_after(self(), :kill, timeout)
  end
end
