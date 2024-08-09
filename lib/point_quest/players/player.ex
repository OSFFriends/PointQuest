defmodule PointQuest.Players.Player do
  use Ecto.Schema

  alias PointQuest.Players.Glyph
  alias PointQuest.Players.Character

  @type t :: %__MODULE__{
          player_id: String.t(),
          character: Character.t(),
          # TODO: need to handle multiple glyphs (to keep it hot and ready stevie beevie :tm:)
          glyph: Glyph.t()
        }

  embedded_schema do
    field :player_id, :string
    embeds_one :character, Character
    embeds_one :glyph, Glyph
  end
end
