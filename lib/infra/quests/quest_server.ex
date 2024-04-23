defmodule Infra.Quests.QuestServer do
  @moduledoc """
  Agent to hold quest state
  """

  use GenServer, restart: :transient

  @type opt ::
          {:quest_id, String.t()}
          | {:timeout, non_neg_integer()}
          | {:max_events, non_neg_integer()}
  @type opts :: [opt(), ...]

  def start_link(opts) do
    {:ok, init_quest} = PointQuest.Quests.Quest.init()

    opts =
      opts
      |> Keyword.take([:timeout, :quest_id, :max_events])
      |> Keyword.put_new(:timeout, :timer.hours(1))
      |> Keyword.put_new(:max_events, 50)
      |> Keyword.put(:snapshot, init_quest)
      |> Map.new()

    GenServer.start_link(
      __MODULE__,
      opts,
      name: {:via, Horde.Registry, {Infra.Quests.Registry, opts.quest_id}}
    )
  end

  def get_snapshot(server) do
    GenServer.call(server, {:get_snapshot})
  end

  def get_events(server) do
    GenServer.call(server, {:get_events})
  end

  def add_event(server, event) do
    GenServer.call(server, {:add_event, event})
  end

  # GENSERVER CALLBACKS

  def init(%{timeout: timeout} = opts) do
    timeout_ref = schedule_cleanup(timeout)
    state = Map.merge(opts, %{timeout_ref: timeout_ref, events: []})

    {:ok, state}
  end

  def handle_call({:add_event, event}, _from, state) do
    :erlang.cancel_timer(state.timeout_ref)
    # new event gets added at the tail after possibly taking a new snapshot
    # doing this to optimize readers over writers (read doesn't need to enum reverse)
    state =
      if length(state.events) >= state.max_events do
        drop_count = div(state.max_events, 2)

        new_snapshot =
          state.events
          |> Enum.take(drop_count)
          |> Enum.reduce(state.snapshot, &PointQuest.Quests.Quest.project/2)

        %{state | events: Enum.drop(state.events, drop_count) ++ [event], snapshot: new_snapshot}
      else
        Map.update!(state, :events, fn events -> events ++ [event] end)
      end

    {:reply, event, Map.put(state, :timeout_ref, schedule_cleanup(state.timeout))}
  end

  def handle_call({:get_snapshot}, _from, state) do
    {:reply, state.snapshot, state}
  end

  def handle_call({:get_events}, _from, state) do
    {:reply, state.events, state}
  end

  def handle_info(:kill, _state) do
    Process.exit(self(), :shutdown)
  end

  defp schedule_cleanup(timeout) do
    Process.send_after(self(), :kill, timeout)
  end
end
