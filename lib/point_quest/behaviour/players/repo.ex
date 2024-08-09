defmodule PointQuest.Behaviour.Players.Repo do
  alias PointQuest.Players
  alias PointQuest.Error

  @type guild_lookup :: {Players.Glyph.GuildEnum.t(), id :: any()}

  @callback write(Players.Character.t(), struct()) :: {:ok, struct()}
  @callback write(Players.Glyph.t(), struct()) :: {:ok, struct()}

  @callback get_glyph_by_guild(guild_lookup()) ::
              {:ok, Players.Glyph.t()} | {:error, Error.NotFound.t(:glyph)}
end
