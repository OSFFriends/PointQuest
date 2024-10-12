defmodule PointQuest.Quests.Commands.GetPartyLeader do
  @moduledoc """
  Gets an adventurer's details given a quest and adventurer id.

  As this is a get command, it does not modify the quest state, only queries it.

  Run the query by calling `new!/1`/`new/1` and passing the returned command to `execute/1`.

  This is primarily used by the authentication module to validate that the party leader actor
  parsed from a token is a valid party leader.
  """
  use PointQuest.Valuable
  alias PointQuest.Behaviour.Quests.Repo, as: QuestRepo
  alias PointQuest.Error

  @type t :: %__MODULE__{
          quest_id: String.t(),
          leader_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    field :leader_id, :string
  end

  @spec execute(t()) ::
          {:ok, PointQuest.Quests.PartyLeader.t()}
          | {:error, Error.NotFound.t(:quest)}
  @doc """
  Executes the query to return the adventurer, if found.

  ```elixir
  PointQuest.Quests.Commands.GetPartyLeader.new!(%{quest_id: "abcd1234", leader_id: "efgh5678"})
  |> PointQuest.Quests.Commands.GetPartyLeader.execute()

  {:ok,
  %PointQuest.Quests.PartyLeader{
   id: "efgh5678",
   quest_id: "abcd1234",
   adventurer: %PointQuest.Quests.Adventurer{
     id: "ijkl9012",
     name: "Proto Leilani",
     class: :mage,
     quest_id: "abcd1234"
   }
  }}
  ```
  """
  def execute(%__MODULE__{quest_id: quest_id, leader_id: leader_id}) do
    QuestRepo.get_party_leader_by_id(quest_id, leader_id)
  end
end
