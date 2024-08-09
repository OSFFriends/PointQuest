defmodule PointQuest.Players.Commands.CreateCharacter do
  @moduledoc """
  Creates a new character class associated to a player.
  """
  use PointQuest.Valuable, optional_fields: [:character_id]
  alias PointQuest.Players

  embedded_schema do
    field :player_id, :string
    field :character_id, :string
    field :name, :string
    field :class, Players.Character.ClassEnum
  end

  def execute(%__MODULE__{} = create_character, _actor) do
    # for now, just delegate to handle
    Players.Character.handle(create_character, nil)
  end
end
