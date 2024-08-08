defmodule PointQuest.Players.Glyph do
  @moduledoc """
  A glyph identifying that the player information provided to us identifies a
  player accurately. 

  (External provider identity)
  """
  use Ecto.Schema
  import PointQuest.Macros.Enum

  defenum ProviderEnum, :provider, [:github]

  @type t :: %__MODULE__{
          player_id: String.t(),
          provider: ProviderEnum.t(),
          external_provider_id: String.t(),
          external_provider_raw_data: map()
        }

  embedded_schema do
    field :player_id, :string
    field :provider, ProviderEnum
    field :external_provider_id, :string
    field :external_proivder_raw_data, :map
  end
end
