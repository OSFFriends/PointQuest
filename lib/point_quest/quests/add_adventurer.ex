defmodule PointQuest.Quests.AddAdventurer do
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer

  @primary_key false
  embedded_schema do
    field :name
    field :class, Adventurer.ClassEnum
    field :quest_id, :string
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  defp changeset(add_adventurer, params) do
    add_adventurer
    |> cast(params, [:quest_id, :name, :class])
    |> validate_required([:quest_id, :name])
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  def execute(%__MODULE__{quest_id: quest_id} = add_adventurer_command) do
    # TODO: add telemetry events here
    with {:ok, quest} <- repo().get_quest_by_id(quest_id),
         {:ok, event} <- Quests.Quest.handle(add_adventurer_command, quest) do
      repo().write(
        quest,
        event
      )
    end
  end
end
