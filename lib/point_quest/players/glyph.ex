defmodule PointQuest.Players.Glyph do
  @moduledoc """
  A glyph identifying that the player information provided to us identifies a
  player accurately. 

  (External provider identity)
  """
  use Ecto.Schema
  import PointQuest.Macros.Enum
  alias PointQuest.Players

  defenum GuildEnum, :guild, [:github]

  @type t :: %__MODULE__{
          player_id: String.t(),
          guild: GuildEnum.t(),
          guild_id: String.t(),
          guild_data: map()
        }

  embedded_schema do
    field :player_id, :string
    field :guild, GuildEnum
    field :guild_id, :string
    field :guild_data, :map
  end

  def init() do
    %__MODULE__{}
  end

  def project(%Players.Event.GlyphCreated{} = event, %__MODULE__{} = glyph) do
    %__MODULE__{
      glyph
      | player_id: event.player_id,
        guild: event.guild,
        guild_id: event.guild_id,
        guild_data: event.guild_data
    }
  end

  def handle(%Players.Commands.EnsureGlyph{} = ensure_glyph, %__MODULE__{guild_id: nil} = _glyph) do
    event =
      ensure_glyph
      |> Map.take([:player_id, :guild, :guild_id, :guild_data])
      |> Map.put_new(:player_id, ExULID.ULID.generate())
      |> Players.Event.GlyphCreated.new!()

    {:ok, event}
  end

  def handle(%Players.Commands.EnsureGlyph{} = _ensure_glyph, _existing_glyph) do
    :ok
  end
end
