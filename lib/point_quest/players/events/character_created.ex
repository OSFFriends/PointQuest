defmodule PointQuest.Players.Event.CharacterCreated do
  use PointQuest.Valuable
  alias PointQuest.Players

  embedded_schema do
    field :name, :string
    field :player_id, :string
    field :character_id, :string
    field :class, Players.Character.ClassEnum
  end
end
