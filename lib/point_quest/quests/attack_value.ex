defmodule PointQuest.Quests.AttackValue do
  use Ecto.Type

  @type t :: non_neg_integer()

  @valid_attacks [0, 1, 2, 3, 5, 8, 13]

  @impl Ecto.Type
  def type(), do: :integer

  @impl Ecto.Type
  def cast(attack_value) when attack_value in @valid_attacks do
    {:ok, attack_value}
  end

  @impl Ecto.Type
  def cast(_invalid_attack) do
    :error
  end

  @impl Ecto.Type
  def load(attack_value), do: {:ok, attack_value}

  @impl Ecto.Type
  def dump(attack_value), do: {:ok, attack_value}

  @spec valid_attacks() :: [integer(), ...]
  def valid_attacks(), do: @valid_attacks
end
