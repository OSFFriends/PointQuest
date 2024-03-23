defmodule Infra.TelemetryWatcherTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias Infra.TelemetryWatcher

  @crash [:telemetry_watcher, :test, :crash]

  defmodule Handler do
    require Logger

    @crash [:telemetry_watcher, :test, :crash]

    @spec attach() :: :ok
    def attach() do
      :telemetry.attach_many(
        __MODULE__,
        [
          @crash
        ],
        &__MODULE__.handle_event/4,
        nil
      )
    end

    @spec handle_event([atom()], map(), map(), nil) :: nil
    def handle_event(@crash, _measurements, _context, nil) do
      raise ArgumentError, "forced telemetry crash"
    end
  end

  setup do
    start_supervised!({TelemetryWatcher, name: __MODULE__, handlers: [Handler]})

    :ok
  end

  test "handler is attached at startup" do
    assert {:error, :already_exists} = Handler.attach()
  end

  test "handler is reattached in case of crash" do
    # Hook into handler crash for verification
    :telemetry_test.attach_event_handlers(self(), [[:telemetry, :handler, :failure]])

    # produces error logs that clog up test output
    capture_log(fn ->
      :telemetry.execute(@crash, %{}, %{})
    end)

    # verify that handler did crash
    assert_received {[:telemetry, :handler, :failure], _ref, _measurements,
                     %{handler_id: Handler}}

    # But was reattached by telemetry watcher
    assert [%{id: Handler}] = :telemetry.list_handlers(@crash)
  end
end
