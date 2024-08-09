defmodule PointQuest.Players.Event.GlyphCreated do
  use PointQuest.Valuable
  alias PointQuest.Players.Glyph

  @type t :: %__MODULE__{
          player_id: String.t(),
          guild: Glyph.GuildEnum.t(),
          guild_id: String.t(),
          guild_data: map()
        }

  embedded_schema do
    field :player_id, :string
    field :guild, Glyph.GuildEnum
    field :guild_id, :string
    field :guild_data, :map
  end
end
