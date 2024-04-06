defmodule Infra.Quests.QuestReader do
  alias Projectionist.Reader

  @type t :: %__MODULE__{
          snapshot?: boolean()
        }

  @enforce_keys [:snapshot?]
  defstruct [:snapshot?]

  def new(params), do: struct!(__MODULE__, params)

  defimpl Projectionist.Reader do
    alias Infra.Quests.QuestReader

    # If we are the snapshot we only have one record we can pull
    # we don't yet support saving multiple old snapshots
    def read(%QuestReader{snapshot?: true}, %Reader.Read{id: quest_id}) do
      [
        # This is the data shape that projectionist expects snapshots to return
        # since we don't have historical snapshots we just play along
        %{
          data:
            Infra.Quests.QuestServer.get_snapshot(
              {:via, Registry, {Infra.Quests.Registry, quest_id}}
            ),
          version: 1
        }
      ]
    end

    # we just grab all events in the current event store
    # we don't yet support persisting events anywhere
    def read(%QuestReader{snapshot?: false}, %Reader.Read{id: quest_id}) do
      Infra.Quests.QuestServer.get_events({:via, Registry, {Infra.Quests.Registry, quest_id}})
    end

    def stream(%QuestReader{snapshot?: true}, %Reader.Read{id: quest_id}, callback) do
      callback.([
        # This is the data shape that projectionist expects snapshots to return
        # since we don't have historical snapshots we just play along
        %{
          data:
            Infra.Quests.QuestServer.get_snapshot(
              {:via, Registry, {Infra.Quests.Registry, quest_id}}
            )
        },
        version: 1
      ])
    end

    def stream(%QuestReader{snapshot?: false}, %Reader.Read{id: quest_id}, callback) do
      callback.(
        Infra.Quests.QuestServer.get_events({:via, Registry, {Infra.Quests.Registry, quest_id}})
      )
    end
  end
end
