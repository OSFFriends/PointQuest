defmodule Infra.TelemetryWatcher do
  @moduledoc """
  Watcher that will ensure a set of handlers are reattached in case of failure.

  ## Options

  * `name` [Infra.TelemetryWatcher] - name of TelemetryWatcher process
  * `handlers` - list of modules with `attach/0` that attaches to telemetry events

  ## Defining handlers

  Handlers are expected to be modules with an `attatch/0` function that
  attaches them to the `:telemetry` events they handle.

  ```elixir
  defmodule MyApp.TelemetryHandler do
    @spec attach() :: :ok
    def attach() do
    :telemetry.attach_many(
      __MODULE__,
      [
        [:my_app, :create_account, :start],
        [:my_app, :create_account, :stop]
      ],
      &__MODULE__.handle_event/4,
      nil
    end
  end
  ```

  And then add to Telemetry watcher in supervision tree along with desired
  handlers.
  ```elixir
  defmodule MyApp.Application do
    def start(_type, _args) do
      children = [
        {TelemetryWatcher, handlers: [MyApp.TelemetryHandler]}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
    end
  end
  ```

  """
  use GenServer

  require Logger

  @type handlers :: {:handlers, [module()]}
  @type name :: atom()
  @type opts :: [handlers() | name()]

  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def handle_failed_handler([:telemetry, :handler, :failure], %{}, failure_metadata, opts) do
    GenServer.call(opts[:watcher], {:handle_failure, failure_metadata})
  end

  @impl GenServer
  def init(opts) do
    Enum.each(opts[:handlers], fn handler -> handler.attach() end)

    :telemetry.attach(
      opts[:name],
      [:telemetry, :handler, :failure],
      &__MODULE__.handle_failed_handler/4,
      watcher: opts[:name]
    )

    {:ok, opts}
  end

  @impl GenServer
  def handle_call({:handle_failure, %{handler_id: handler_id}}, _from, state) do
    if Enum.any?(state[:handlers], fn handler -> handler == handler_id end) do
      Logger.info("Crashed handler #{handler_id} being reattached by Telemetry Watcher")
      handler_id.attach()
    else
      Logger.info("Crashed handler #{handler_id} not monitored by Telemetry Watcher - Skipping")
    end

    {:reply, :ok, state}
  end
end
