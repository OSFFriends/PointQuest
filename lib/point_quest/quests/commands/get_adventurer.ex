defmodule PointQuest.Quests.Commands.GetAdventurer do
  @moduledoc """
  Gets an adventurer's details given a quest and adventurer id.

  As this is a get command, it does not modify the quest state, only queries it.

  Run the query by calling `new!/1`/`new/1` and passing the returned command to `execute/1`.
  """
  use PointQuest.Valuable
  alias PointQuest.Error

  @type t :: %__MODULE__{
          quest_id: String.t(),
          adventurer_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :adventurer_id, :string
  end

  @spec execute(t()) ::
          {:ok, PointQuest.Quests.Adventurer.t()}
          | {:error, Error.NotFound.t(:adventurer | :quest)}
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
    PointQuest.quest_repo().get_adventurer_by_id(quest_id, adventurer_id)
  end
end
