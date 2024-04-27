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
  use PointQuest.Valuable

  alias PointQuest.Quests
  alias PointQuest.Quests.Adventurer

  require PointQuest.Quests.Telemetry
  require Telemetrex

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

  @spec changeset(t(), map()) :: Ecto.Changeset.t(t())
  @doc """
  Creates a changeset from add_adventurer struct and params.

  When backing a form, this allows for easy validation of the form state.
  """
  def changeset(add_adventurer, params) do
    add_adventurer
    |> cast(params, [:quest_id, :name, :class])
    |> validate_required([:quest_id, :name])
    |> ensure_unique_name()
  end

  defp ensure_unique_name(changeset) do
    with {:ok, %{party: %{adventurers: adventurers, party_leader: leader}}} <-
           PointQuest.quest_repo().get_quest_by_id(get_field(changeset, :quest_id)) do
      name = get_field(changeset, :name)

      adventurers =
        if is_nil(leader.adventurer) do
          adventurers
        else
          [leader.adventurer | adventurers]
        end

      if not is_nil(name) and
           Enum.any?(adventurers, fn a ->
             String.downcase(a.name) == String.downcase(name)
           end) do
        Ecto.Changeset.add_error(changeset, :name, "name must be unique among party members")
      else
        changeset
      end
    end
  end

  @spec execute(t()) :: PointQuest.Quests.Quest.t()
  @doc """
  Executes the command to update the quest state.

  Returns the event for adding the adventurer.

  ```elixir
  command = PointQuest.Quests.Commands.AddAdventurer.new!(%{name: "Stevey Beevey", class: :knight, quest_id: "abcd1234"})
  PointQuest.Quests.Commands.AddAdventurer.execute(command)
  ```
  """
  def execute(%__MODULE__{quest_id: quest_id} = add_adventurer_command) do
    Telemetrex.span event: Quests.Telemetry.add_adventurer(),
                    context: %{command: add_adventurer_command} do
      with {:ok, quest} <- PointQuest.quest_repo().get_quest_by_id(quest_id),
           {:ok, event} <- Quests.Quest.handle(add_adventurer_command, quest),
           {:ok, _quest} <-
             PointQuest.quest_repo().write(
               quest,
               event
             ) do
        {:ok, event}
      end
    after
      {:ok, event} -> %{event: event}
      {:error, reason} -> %{error: true, reason: reason}
    end
  end
end
