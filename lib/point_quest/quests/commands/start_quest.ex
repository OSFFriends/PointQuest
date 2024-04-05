defmodule PointQuest.Quests.Commands.StartQuest do
  @moduledoc """
  Command to add start a quest.

  Ensure that you're calling either `new/1` or `new!/1` followed by `execute/1` in order to
  create the quest.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests

  require PointQuest.Quests.Telemetry
  require Telemetrex

  defmodule PartyLeadersAdventurer do
    @moduledoc """
    The adventurer for the party leader when participating in the quest.
    """
    use Ecto.Schema

    import Ecto.Changeset

    alias PointQuest.Quests.Adventurer

    @type t :: %__MODULE__{
            name: String.t(),
            class: Adventurer.Class.NameEnum.t()
          }

    @primary_key {:id, :binary_id, autogenerate: true}
    embedded_schema do
      field :name, :string
      field :class, Adventurer.Class.NameEnum
    end

    def changeset(adventurer, params \\ %{}) do
      adventurer
      |> cast(params, [:name, :class])
      |> Adventurer.Class.maybe_default_class()
      |> validate_required([:name])
    end
  end

  @type t :: %__MODULE__{
          name: String.t(),
          party_leaders_adventurer: PartyLeadersAdventurer.t()
        }

  @primary_key false
  embedded_schema do
    field :name, :string
    embeds_one :party_leaders_adventurer, PartyLeadersAdventurer
  end

  @spec new(map()) :: t()
  @doc """
  Creates a command for starting the quest from params.

  Returns a response tuple with the quest. Realistically, this can only succeed in our
  current configuration.

  ```elixir
  PointQuest.Quests.Commands.StartQuest.new(%{name: "Example Quest", party_leaders_adventurer: %{class: :knight, name: "Stevey Beevey"}})

  {:ok,
    %PointQuest.Quests.Commands.StartQuest{
     name: "Example Quest",
     party_leaders_adventurer: %PointQuest.Quests.Commands.StartQuest.PartyLeadersAdventurer{
       id: nil,
       name: "Stevey Beevey",
       class: :knight
     }
  }}
  ```
  """
  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  @spec new!(map()) :: t()
  @doc """
  Creates a command for starting the quest from params.

  Returns the quest if successful, otherwise raises. Realistically, this can only succeed in our
  current configuration.

  ```elixir
  PointQuest.Quests.Commands.StartQuest.new!(%{name: "Example Quest", party_leaders_adventurer: %{class: :knight, name: "Stevey Beevey"}})

  %PointQuest.Quests.Commands.StartQuest{
     name: "Example Quest",
     party_leaders_adventurer: %PointQuest.Quests.Commands.StartQuest.PartyLeadersAdventurer{
       id: nil,
       name: "Stevey Beevey",
       class: :knight
     }
  }
  ```
  """
  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:insert)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t(t())
  @doc """
  Creates a changeset from start_quest struct and params.

  When backing a form, this allows for easy validation of the form state.
  """
  def changeset(start_quest, params \\ %{}) do
    start_quest
    |> cast(params, [:name])
    |> cast_embed(:party_leaders_adventurer)
    |> validate_required([:name])
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  @spec execute(t()) :: PointQuest.Quests.Quest.t()
  @doc """
  Executes the command to start the quest.

  Returns the new quest.

  ```elixir
  PointQuest.Quests.Commands.StartQuest.new!(%{name: "Example Quest", party_leaders_adventurer: %{class: :knight, name: "Stevey Beevey"}})
  |> PointQuest.Quests.Commands.StartQuest.execute()

  {:ok,
  %PointQuest.Quests.Quest{
    id: "XHCV7TZ2",
    adventurers: [],
    attacks: [],
    party_leader: %PointQuest.Quests.PartyLeader{
      id: "FQaBVAHr",
      quest_id: "XHCV7TZ2",
      adventurer: %PointQuest.Quests.Adventurer{
        id: "qkQ07CO7",
        name: "Stevey Beevey",
        class: :knight,
        quest_id: "XHCV7TZ2"
      }
    },
    name: "Example Quest",
    all_adventurers_attacking?: false
  }}
  ```
  """
  def execute(%__MODULE__{} = start_quest_command) do
    Telemetrex.span event: Quests.Telemetry.quest_started(),
                    context: %{command: start_quest_command} do
      with {:ok, event} <- Quests.Quest.handle(start_quest_command, %Quests.Quest{}) do
        repo().write(
          %Quests.Quest{},
          event
        )
      end
    after
      {:ok, event} -> %{event: event}
      {:error, error} -> %{error: true, reason: error}
    end
  end
end
