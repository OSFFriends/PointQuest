defmodule PointQuest.Players.Commands.EnsureGlyph do
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

  def execute(%__MODULE__{} = ensure_glyph, opts) do
    repo = Keyword.get(opts, :player_repo, PointQuest.player_repo())

    with {:error, %PointQuest.Error.NotFound{resource: :glyph}} <-
           repo.get_glyph_by_guild({ensure_glyph.guild, ensure_glyph.guild_id}),
         {:ok, %PointQuest.Players.Event.GlyphCreated{} = glyph_created} <-
           Glyph.handle(ensure_glyph, Glyph.init()),
      {:ok, _event} <- Infra.Players.Couch.Db.write(Glyph.init(), glyph_created) do
      {:ok, Glyph.project(glyph_created, Glyph.init())}
    end
  end
end
