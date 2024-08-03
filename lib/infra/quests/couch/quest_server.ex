defmodule Infra.Quests.Couch.QuestServer do
  use GenServer
  alias Infra.Quests.Couch.QuestSnapshots
  alias PointQuest.Quests.Quest

  def start_link(opts) do
    opts =
      opts
      |> Keyword.take([:timeout, :quest_id])
      |> Keyword.put_new(:timeout, :timer.hours(1))
      |> Map.new()

    GenServer.start_link(
      __MODULE__,
      opts,
      name: {:via, Horde.Registry, {Infra.Quests.Couch.Registry, opts.quest_id}}
    )
  end

  def get(server) do
    GenServer.call(server, :get_quest)
  end

  def add_event(nil, {:add_event, _event}) do
    {:error, PointQuest.Error.NotFound.exception(reource: :quest)}
  end

  def add_event(server, event) do
    GenServer.call(server, {:add_event, event})
  end

  # GENSERVER CALLBACKS

  def init(%{timeout: timeout, quest_id: quest_id} = opts) do
    timeout_ref = schedule_cleanup(timeout)

    state = Map.merge(opts, %{timeout_ref: timeout_ref, events_seen: 0, last_event_id: nil})

    case fetch_quest(quest_id) do
      {:error, %PointQuest.Error.NotFound{} = not_found} ->
        {:stop, not_found}

      {:ok, quest_state} ->
        state = Map.merge(state, quest_state)
        maybe_snapshot(state)
        {:ok, state}
    end
  end

  def handle_call(:get_quest, _from, %{quest: quest} = state) do
    {:reply, quest, state}
  end

  def handle_call({:add_event, event}, _from, state) do
    with {:ok, doc} <-
           CouchDB.put(
             "/events-v2/quest-#{state.quest_id}:#{ExULID.ULID.generate()}",
             event
           ),
         {:ok, quest_state} <- fetch_quest(state.quest_id) do
      state = Map.merge(state, quest_state)
      maybe_snapshot(state)
      {:reply, {:ok, Map.put(event, :id, doc["id"])}, state}
    end
  end

  def handle_info(:kill, _state) do
    Process.exit(self(), :shutdown)
  end

  def handle_info({:snapshot, snapshot, version}, state) do
    :ok =
      QuestSnapshots.write_snapshot(%{
        version: version,
        snapshot: snapshot
      })

    {:ok, quest_state} = fetch_quest(state.quest_id)
    {:noreply, Map.merge(state, quest_state)}
  end

  defp schedule_cleanup(timeout) do
    Process.send_after(self(), :kill, timeout)
  end

  defp fetch_quest(quest_id, limit \\ :infinity) do
    case QuestSnapshots.get_snapshot(quest_id) do
      nil ->
        init_quest = Quest.init()

        "/events-v2/_partition/quest-#{quest_id}/_all_docs"
        |> CouchDB.paginate_view(%{})
        |> maybe_limit(limit)
        |> Enum.reduce({init_quest, 0, _last_event_seen = nil}, fn event,
                                                                   {quest, events_seen,
                                                                    _last_event_seen} ->
          {
            Quest.project(event, quest),
            events_seen + 1,
            event.id
          }
        end)
        |> case do
          {%{id: nil}, _count} ->
            {:error, PointQuest.Error.NotFound.exception(reource: :quest)}

          {quest, events_seen, last_event_id} ->
            {:ok, %{quest: quest, events_seen: events_seen, last_event_id: last_event_id}}
        end

      %{snapshot: snapshot, version: version} ->
        {quest, events_seen, last_event_id} =
          "events-v2/_partition/quest-#{quest_id}/_all_docs"
          |> CouchDB.paginate_view(%{
            start_key: version <> "\ufff0"
          })
          |> maybe_limit(limit)
          |> Enum.reduce({snapshot, 0, _last_event_seen = nil}, fn event,
                                                                   {quest, events_seen,
                                                                    _last_event_seen} ->
            {
              Quest.project(event, quest),
              events_seen + 1,
              event.id
            }
          end)

        {:ok, %{quest: quest, events_seen: events_seen, last_event_id: last_event_id}}
    end
  end

  defp maybe_snapshot(%{quest_id: quest_id, events_seen: seen}) when seen >= 10 do
    half = 2
    {:ok, %{last_event_id: version, quest: snapshot}} = fetch_quest(quest_id, div(seen, half))
    send(self(), {:snapshot, snapshot, version})
  end

  defp maybe_snapshot(state) do
    state
  end

  defp maybe_limit(stream, :infinity), do: stream
  defp maybe_limit(stream, count), do: Stream.take(stream, count)
end
