defmodule PointQuest.Telemetry do
  @doc """
  Given a `name` and an `event` prefix generates macros that can build `event`
  along with start/stop suffixes.

  ## Usage

  Given the following module:
  ```elixir
  defmodule PointQuest.Quest.Telemetry do
    import PointQuest.Telemetry

    defevent :create, [:portal, :quest, :create]
  end
  ```

  The `PointQuest.Quest.Telemetry.create/0` and
  macros `PointQuest.Quest.Telemetry.create/1` now exits that can be used to
  reference the telemetry events.

  ```elixir
  defmodule Infra.Logging.Quest do
    require PointQuest.Quest.Telemetry
    require Logger

    def attach() do
      :telemetry.attach_many(
        "my-handler",
        [
          PointQuest.Quest.Telemetry.create(:start),
          PointQuest.Quest.Telemetry.create(:stop),
        ],
        &handle_event/4,
        nil
      )
    end

    def handle_event(PointQuest.Quest.Telemetry.create(:start), _measurements, _context, _config) do
      Logger.info("Creating new quest")
    end

    def handle_event(PointQuest.Quest.Telemetry.create(:stop), _measurements, _context, _config) do
      Logger.info("Quest created")
    end
  end
  ```
  """
  defmacro defevent(name, event) do
    quote bind_quoted: [name: name, event: event] do
      defmacro unquote(name)() do
        unquote(event)
      end

      defmacro unquote(name)(:start) do
        Enum.concat(unquote(event), [:start])
      end

      defmacro unquote(name)(:stop) do
        Enum.concat(unquote(event), [:stop])
      end
    end
  end
end
