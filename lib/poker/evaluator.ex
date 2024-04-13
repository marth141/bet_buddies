defmodule Poker.Evaluator do
  alias Poker.Card

  def report(list_of_cards) do
    high_card = high_card?(list_of_cards)

    best =
      [
        royal_flush: royal_flush?(list_of_cards),
        straight_flush: straight_flush?(list_of_cards),
        four_of_a_kind: four_of_a_kind?(list_of_cards),
        full_house: full_house?(list_of_cards),
        flush: flush?(list_of_cards),
        straight: straight?(list_of_cards),
        three_of_a_kind: three_of_a_kind?(list_of_cards),
        two_pair: two_pair?(list_of_cards),
        one_pair: one_pair?(list_of_cards)
      ]
      |> get_best()

    %{high_card: high_card, best: best}
  end

  def get_best(report) do
    Enum.find(report, fn
      {:royal_flush, value} -> value
      {:straight_flush, value} -> value
      {:four_of_a_kind, value} -> value
      {:full_house, value} -> value
      {:flush, value} -> value
      {:straight, value} -> value
      {:three_of_a_kind, value} -> value
      {:two_pair, value} -> value
      {:one_pair, value} -> value
    end)
  end

  @spec royal_flush?(list(Card)) :: true | false
  def royal_flush?(list_of_cards) do
    royal_flush_exists = true
    no_royal_flush_exists = false

    card_suit_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.suit end)
      |> Enum.filter(fn {_suit, cards} -> Enum.count(cards) >= 5 end)

    case card_suit_group do
      [] ->
        no_royal_flush_exists

      [{_suit, cards}] ->
        card_count =
          Enum.sort_by(cards, fn %Card{} = card -> card.high_numerical_value end)
          |> Enum.reduce([], fn
            %Card{high_numerical_value: 10} = card, acc ->
              [card] ++ acc

            %Card{high_numerical_value: 11} = card, acc ->
              [card] ++ acc

            %Card{high_numerical_value: 12} = card, acc ->
              [card] ++ acc

            %Card{high_numerical_value: 13} = card, acc ->
              [card] ++ acc

            %Card{high_numerical_value: 14} = card, acc ->
              [card] ++ acc

            _card, acc ->
              acc
          end)
          |> Enum.count()

        if card_count == 5 do
          royal_flush_exists
        else
          no_royal_flush_exists
        end
    end
  end

  def straight_flush?(list_of_cards) do
    straight_flush_exists = true
    no_straight_flush_exists = false

    card_suit_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.suit end)
      |> Enum.filter(fn {_suit, cards} -> Enum.count(cards) >= 5 end)

    case card_suit_group do
      [] ->
        no_straight_flush_exists

      [{_suit, cards}] ->
        with {true, _cards} <-
               Enum.sort_by(cards, fn %Card{} = card -> card.low_numerical_value end)
               |> Enum.chunk_every(5, 1, :discard)
               |> Enum.map(&five_in_sequence?(&1))
               |> Enum.reject(fn {key, _cards} -> key == false end)
               |> List.last() do
          straight_flush_exists
        else
          nil -> no_straight_flush_exists
        end
    end
  end

  def four_of_a_kind?(list_of_cards) do
    four_of_a_kind_exists = true
    no_four_of_a_kind = false

    card_values_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.literal_value end)
      |> Enum.filter(fn {_literal_values, cards} -> Enum.count(cards) == 4 end)

    case card_values_group do
      [] ->
        no_four_of_a_kind

      [{_suit, _cards}] ->
        four_of_a_kind_exists
    end
  end

  def full_house?(list_of_cards) do
    full_house_exists = true
    no_full_house = false

    card_values_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.literal_value end)
      |> Enum.filter(fn
        {_literal_values, cards} when length(cards) == 3 -> true
        {_literal_values, cards} when length(cards) == 2 -> true
        {_literal_values, _cards} -> false
      end)
      |> Enum.map(fn {_key, cards} -> Enum.count(cards) end)

    if Enum.member?(card_values_group, 2) and Enum.member?(card_values_group, 3) do
      full_house_exists
    else
      no_full_house
    end
  end

  def flush?(list_of_cards) do
    flush_exists = true
    no_flush_exists = false

    card_suit_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.suit end)
      |> Enum.filter(fn {_suit, cards} -> Enum.count(cards) >= 5 end)

    case card_suit_group do
      [] -> no_flush_exists
      _ -> flush_exists
    end
  end

  def straight?(list_of_cards) do
    straight_exists = true
    no_straight_exists = false

    with {true, _cards} <-
           Enum.sort_by(list_of_cards, fn %Card{} = card -> card.low_numerical_value end)
           |> Enum.chunk_every(5, 1, :discard)
           |> Enum.map(&five_in_sequence?(&1))
           |> Enum.reject(fn {key, _cards} -> key == false end)
           |> List.last() do
      straight_exists
    else
      nil -> no_straight_exists
    end
  end

  def three_of_a_kind?(list_of_cards) do
    three_of_a_kind_exists = true
    no_three_of_a_kind_exists = false

    card_values_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.literal_value end)
      |> Enum.filter(fn {_literal_values, cards} -> Enum.count(cards) == 3 end)

    case card_values_group do
      [] ->
        no_three_of_a_kind_exists

      [{_suit, _cards}] ->
        three_of_a_kind_exists
    end
  end

  def two_pair?(list_of_cards) do
    two_pair_exists = true
    no_two_pair_exists = false

    card_values_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.literal_value end)
      |> Enum.filter(fn {_literal_values, cards} -> Enum.count(cards) == 2 end)
      |> Map.new()
      |> Map.values()
      |> Enum.sort_by(fn [%Card{high_numerical_value: value} | _cards] -> value end, :desc)
      |> IO.inspect()

    with [pair1, pair2 | _the_rest] <- card_values_group do
      highest_pair = [pair1, pair2]
      %{type: :two_pair, exists?: two_pair_exists, cards: highest_pair}
    else
      _ -> %{type: :two_pair, exists?: no_two_pair_exists, cards: []}
    end
  end

  def one_pair?(list_of_cards) do
    pair_exists = true
    no_pair_exists = false

    card_values_group =
      Enum.group_by(list_of_cards, fn %Card{} = card -> card.high_numerical_value end)
      |> Enum.filter(fn {_literal_values, cards} -> Enum.count(cards) == 2 end)
      |> Map.new()
      |> Map.values()
      |> Enum.sort_by(fn [%Card{high_numerical_value: value} | _cards] -> value end)
      |> List.last()

    case card_values_group do
      nil ->
        %{type: :one_pair, exists?: no_pair_exists, cards: []}

      _ ->
        %{type: :one_pair, exists?: pair_exists, cards: card_values_group}
    end
  end

  def high_card?(list_of_cards) do
    Enum.sort_by(list_of_cards, fn %Card{} = card -> card.high_numerical_value end)
    |> List.last()
  end

  defp five_in_sequence?(list), do: check_sequence(list, nil, [])
  defp check_sequence([], card_ah, acc), do: {true, [card_ah | acc]}
  defp check_sequence([%Card{} = card_h | t], nil, acc), do: check_sequence(t, card_h, acc)

  defp check_sequence([%Card{} = card_h | t], %Card{} = card_ah, acc)
       when card_ah.low_numerical_value == card_h.low_numerical_value - 1,
       do: check_sequence(t, card_h, [card_ah | acc])

  defp check_sequence(_, _, acc), do: {false, acc}
end