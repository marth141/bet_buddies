defmodule Poker.Player do
  alias Poker.Player
  use Ecto.Schema

  embedded_schema do
    field :player_id, :string
    field :name, :string
    field :wallet, :integer, default: 0
    field :bet, :integer, default: 0
    field :hand, {:array, :map}, default: []
    field :is_host?, :boolean, default: false
    field :is_big_blind?, :boolean, default: false
    field :is_small_blind?, :boolean, default: false
    field :is_under_the_gun?, :boolean, default: false
    field :number, :integer, default: 0
    field :folded?, :boolean, default: true
  end

  # Rules

  @spec has_enough_money?(%Player{}, integer()) :: boolean()
  def has_enough_money?(%Player{wallet: wallet}, amount_to_spend) do
    wallet > amount_to_spend
  end

  # Transformations

  @spec add_to_bet(%Player{}, integer()) :: %Player{}
  def add_to_bet(%Player{} = player, amount_to_add) do
    Map.update!(player, :bet, fn bet -> bet + amount_to_add end)
  end

  @spec deduct_from_wallet(%Player{}, integer()) :: %Player{}
  def deduct_from_wallet(%Player{} = player, amount_to_deduct) do
    Map.update!(player, :wallet, fn wallet -> wallet - amount_to_deduct end)
  end

  @spec set_folded(%Player{}, boolean()) :: %Player{}
  def set_folded(%Player{} = player, status) do
    Map.update!(player, :folded?, fn _ -> status end)
  end
end
