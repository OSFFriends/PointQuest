defmodule PointQuest.Quests.Commands.StartQuest do
  @moduledoc """
  Command to add start a quest.

  Ensure that you're calling either `new/1` or `new!/1` followed by `execute/1` in order to
  create the quest.
  """
  use PointQuest.Valuable, optional_fields: [:party_leaders_adventurer]

  alias PointQuest.Quests

  require PointQuest.Quests.Telemetry
  require Telemetrex

  defmodule PartyLeadersAdventurer do
    @moduledoc """
    The adventurer for the party leader when participating in the quest.
    """
    use PointQuest.Valuable

    alias PointQuest.Quests.Adventurer

    @type t :: %__MODULE__{
            name: String.t(),
            class: Adventurer.Class.NameEnum.t()
          }

    @primary_key false
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
          quest_id: String.t(),
          party_leaders_adventurer: PartyLeadersAdventurer.t()
        }

  @primary_key false
  embedded_schema do
    field :quest_id, :string
    embeds_one :party_leaders_adventurer, PartyLeadersAdventurer
  end

  def changeset(start_quest, params) do
    start_quest
    |> cast(params, [:quest_id])
    |> maybe_new_quest_id()
    |> validate_required([:quest_id])
    |> cast_embed(:party_leaders_adventurer)
  end

  def maybe_new_quest_id(changeset) do
    if get_change(changeset, :quest_id) do
      changeset
    else
      change(changeset, quest_id: Nanoid.generate_non_secure())
    end
  end

  @spec execute(t()) :: PointQuest.Quests.Quest.t()
  @doc """
  Executes the command to start the quest.

  Returns the new quest.

  ```elixir
  PointQuest.Quests.Commands.StartQuest.new!(%{party_leaders_adventurer: %{class: :knight, name: "Stevey Beevey"}})
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
        id: "FQaBVAHr",
        name: "Stevey Beevey",
        class: :knight,
        quest_id: "XHCV7TZ2"
      }
    },
  }}
  ```
  """
  def execute(%__MODULE__{} = start_quest_command) do
    {:ok, quest} = Quests.Quest.init()

    Telemetrex.span event: Quests.Telemetry.quest_started(),
                    context: %{command: start_quest_command} do
      with {:ok, event} <- Quests.Quest.handle(start_quest_command, quest),
           :ok <- PointQuest.quest_repo().write(quest, event) do
        {:ok, event}
      end
    after
      {:ok, event} -> %{event: event}
      {:error, error} -> %{error: true, reason: error}
    end
  end
end
