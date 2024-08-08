defmodule PointQuest.Behaviour.Players.CharacterRepo do
  alias PointQuest.Players

  @callback write(Players.Character.t(), struct()) :: {:ok, struct()}
  @callback get_glyph_by_provider_id(external_provider_id :: String.t())
end
