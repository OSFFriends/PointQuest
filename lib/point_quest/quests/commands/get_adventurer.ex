defmodule PointQuest.Quests.Commands.GetAdventurer do
  @moduledoc """
  Gets an adventurer's details given a quest and adventurer id.

  As this is a get command, it does not modify the quest state, only queries it.

  Run the query by calling `new!/1`/`new/1` and passing the returned command to `execute/1`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          quest_id: String.t(),
          adventurer_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :adventurer_id, :string
  end

  @spec new(map()) :: {:ok, t()}
  @doc """
  Creates a new get_adventurer command, with response typing.

  Pass the returned command into `execute/1` to run the query and return the adventurer.

  ```elixir
  PointQuest.Quests.Commands.GetAdventurer.new(%{quest_id: "abcd1234", adventurer_id: "jtn12345"})

  {:ok,
   %PointQuest.Quests.Commands.GetAdventurer{
     quest_id: "abcd1234",
     adventurer_id: "jtn12345"
   }}
  ```
  """
  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:get)
  end

  @spec new!(map()) :: t()
  @doc """
  Creates a new get_adventurer command, raising on failure.

  Pass the returned command into `execute/1` to run the query and return the adventurer.

  ```elixir
  PointQuest.Quests.Commands.GetAdventurer.new!(%{quest_id: "abcd1234", adventurer_id: "jtn12345"})

  %PointQuest.Quests.Commands.GetAdventurer{
   quest_id: "abcd1234",
   adventurer_id: "jtn12345"
  }
  ```
  """
  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:get)
  end

  defp changeset(get_adventurer, params) do
    get_adventurer
    |> cast(params, [:quest_id, :adventurer_id])
    |> validate_required([:quest_id, :adventurer_id])
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  @spec execute(t()) ::
          {:ok, PointQuest.Quests.Adventurer.t()}
          | {:error, :quest_not_found}
          | {:error, :adventurer_not_found}
  @doc """
  Executes the query to return the adventurer, if found.

  ```elixir
  PointQuest.Quests.Commands.GetAdventurer.new!(%{quest_id: "abcd1234", adventurer_id: "jtn12345"})
  |> PointQuest.Quests.Commands.GetAdventurer.execute()

  {:ok,
   %PointQuest.Quests.Adventurer{
     id: "jtn12345",
     name: "JSON new(NAN)",
     class: :healer,
     quest_id: "abcd1234"
   }}
  ```
  """
  def execute(%__MODULE__{quest_id: quest_id, adventurer_id: adventurer_id}) do
    repo().get_adventurer_by_id(quest_id, adventurer_id)
  end
end
