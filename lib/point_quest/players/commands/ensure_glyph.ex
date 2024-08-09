defmodule PointQuest.Players.Commands.GetGlyph do
  use PointQuest.Valuable
  alias PointQuest.Players.Glyph

  # require PointQuest.Players.Telemetry
  # require Telemetrex

  @type t :: %__MODULE__{
          guild: Glyph.GuildEnum.t(),
          guild_id: String.t(),
          guild_data: map()
        }

  embedded_schema do
    field :guild, Glyph.GuildEnum
    field :guild_id, :string
    field :guild_data, :map
  end

  def execute(%__MODULE__{} = get_glyph, opts) do
    repo = Keyword.get(opts, :player_repo, PointQuest.player_repo())
    repo.get_glyph_by_guild({get_glyph.guild, get_glyph.id})
  end
end
