defmodule PointQuest.Quests.Commands.AddAdventurer do
  @moduledoc """
  Command to add adventurer to a quest.

  This adds the adventurer to the `adventurers` list on a `quest` resource. Note that this is
  distinctly separate from the party leader's adventurer (if elected) which will reside on the
  `party_leader` resource.

  Ensure that you're calling either `new/1` or `new!/1` followed by `execute/1` in order to
  update the quest state with these changes.

  Example:

  ```elixir
  # Pipe new!/1 into execute/1
  %{
    name: "JSON new(NAN)",
    class: :knight,
    quest_id: "abcd1234"
  }
  |> PointQuest.Quests.Commands.AddAdventurer.new!()
  |> PointQuest.Quests.Commands.AddAdventurer.execute()

  # another common method is to nest the new!/1 command into execute/1 directly
  PointQuest.Quests.Commands.AddAdventurer.execute(
    PointQuest.Quests.Commands.AddAdventurer.new!(
      %{
        name: "JSON new(NAN)",
        class: :knight,
        quest_id: "abcd1234"
      }
    )
  )


  # or parse the command from the new/1 response tuple and pass it to execute if you need error control flow
  {:ok, add_adventurer_command} = PointQuest.Quests.Commands.AddAdventurer.new(%{name: "Stevey Beevey", class: :mage, quest_id: "abcd1234"})
  PointQuest.Quests.Commands.AddAdventurer.execute(add_adventurer_command)
  ```
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer

  @type t :: %__MODULE__{
          name: String.t(),
          class: Adventurer.Class.NameEnum.t(),
          quest_id: String.t()
        }

  @primary_key false
  embedded_schema do
    field :name, :string
    field :class, Adventurer.Class.NameEnum
    field :quest_id, :string
  end

  @spec new(map()) :: {:ok, t()}
  @doc """
  Creates a command for adding an adventurer to the quest party from params.

  Returns a response object, realistically this can only be {:ok, command} in our current configuration.

  ```elixir
  {:ok, add_adventurer_command} = PointQuest.Quests.Commands.AddAdventurer.new(%{name: "JSON new(NAN)", class: :healer, quest_id: "abcd1234"})
  ```
  """
  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  @spec new!(map()) :: t()
  @doc """
  Creates a command for adding an adventurer to the quest party from params.

  Returns the command if successful, otherwise raises. Realistically, this can only succeed in our
  current configuration.

  ```elixir
  command = PointQuest.Quests.Commands.AddAdventurer.new!(%{name: "Stevey Beevey", class: :knight, quest_id: "abcd1234"})
  ```
  """
  def new!(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action!(:update)
  end

  defp changeset(add_adventurer, params) do
    add_adventurer
    |> cast(params, [:quest_id, :name, :class])
    |> validate_required([:quest_id, :name])
    |> ensure_unique_name()
  end

  defp repo(), do: Application.get_env(:point_quest, PointQuest.Behaviour.Quests.Repo)

  defp ensure_unique_name(changeset) do
    with {:ok, %{adventurers: adventurers, party_leader: leader}} <-
           repo().get_quest_by_id(get_field(changeset, :quest_id)) do
      adventurers =
        if is_nil(leader.adventurer) do
          adventurers
        else
          [leader.adventurer | adventurers]
        end

      if Enum.any?(adventurers, fn a -> a.name == get_field(changeset, :name) end) do
        Ecto.Changeset.add_error(changeset, :name, "name must be unique among party members")
      else
        changeset
      end
    end
  end

  @spec execute(t()) :: PointQuest.Quests.Quest.t()
  @doc """
  Executes the command to update the quest state.

  Returns the updated quest.

  ```elixir
  command = PointQuest.Quests.Commands.AddAdventurer.new!(%{name: "Stevey Beevey", class: :knight, quest_id: "abcd1234"})
  PointQuest.Quests.Commands.AddAdventurer.execute(command)
  ```
  """
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
