defmodule Infra.Quests.Db do
  @moduledoc """
  In-memory DB system
  """
  @behaviour PointQuest.Behaviour.Quests.Repo

  alias Infra.Quests.QuestServer
  alias PointQuest.Quests.Quest
  alias PointQuest.Quests.Event

  defstruct []

  @impl PointQuest.Behaviour.Quests.Repo
  def write(quest, %Event.QuestStarted{} = event) do
    new_quest = Quest.project(event, quest)

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Infra.Quests.QuestSupervisor,
        {QuestServer, quest: new_quest}
      )

    {:ok, new_quest}
  end

  def write(quest, %Event.AdventurerJoinedParty{} = event) do
    new_quest = Quest.project(event, quest)

    server = lookup_quest_server(new_quest.id)
    :ok = QuestServer.update(server, new_quest)

    {:ok, new_quest}
  end

  @impl PointQuest.Behaviour.Quests.Repo
  def get_quest_by_id(quest_id) do
    case lookup_quest_server(quest_id) do
      nil ->
        {:error, :quest_not_found}

      pid ->
        {:ok, QuestServer.get(pid)}
    end
  end

  defp lookup_quest_server(quest_id) do
    case Registry.lookup(Infra.Quests.Registry, quest_id) do
      [{pid, _state}] ->
        pid

      _not_found ->
        nil
    end
  end

  defimpl Projectionist.Reader do
    alias Infra.Quests.Db

    defp get_quest(quest_id) do
      case Infra.Quests.Db.get_quest_by_id(quest_id) do
        {:error, :quest_not_found} ->
          []

        {:ok, quest} ->
          [quest]
      end
    end

    def stream(%Db{}, %Projectionist.Reader.Read{position: :LAST, id: quest_id}, callback) do
      quest = callback.(get_quest(quest_id))

      [%{version: 1, data: quest}]
    end

    def read(%Db{}, %Projectionist.Reader.Read{position: :LAST, id: quest_id}) do
      [%{version: 1, data: get_quest(quest_id)}]
    end
  end
end
