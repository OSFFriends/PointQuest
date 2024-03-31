defmodule PointQuest.Quests.Commands.GetPartyLeader do
  @moduledoc """
  Gets an adventurer's details given a quest and adventurer id.

  As this is a get command, it does not modify the quest state, only queries it.

  Run the query by calling `new!/1`/`new/1` and passing the returned command to `execute/1`.

  This is primarily used by the authentication module to validate that the party leader actor
  parsed from a token is a valid party leader.
  """
  use Ecto.Schema
  import Ecto.Changeset
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

  @spec new(map()) :: {:ok, t()}
  @doc """
  Creates a new get_party_leader command, with response typing.

  Pass the returned command into `execute/1` to run the query and return the party leader.

  ```elixir
  PointQuest.Quests.Commands.GetPartyLeader.new(%{quest_id: "abcd1234", leader_id: "efgh5678"})

  {:ok,
  %PointQuest.Quests.Commands.GetPartyLeader{
   quest_id: "abcd1234",
   leader_id: "efgh5678"
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
  Creates a new get_party_leader command, raising on failure.

  Pass the returned command into `execute/1` to run the query and return the party leader. 

  ```elixir
  PointQuest.Quests.Commands.GetPartyLeader.new(%{quest_id: "abcd1234", leader_id: "efgh5678"})

  %PointQuest.Quests.Commands.GetPartyLeader{
   quest_id: "abcd1234",
   leader_id: "efgh5678"
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
    |> cast(params, [:quest_id, :leader_id])
    |> validate_required([:quest_id, :leader_id])
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

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
    repo().get_party_leader_by_id(quest_id, leader_id)
  end
end
