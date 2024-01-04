defmodule ExPoker.Core.Ranking do
  alias __MODULE__
  alias ExPoker.Core.Card

  @moduledoc """
  这里为德州扑克当中，根据一手（7张）牌，选出最大5张并返回对应结果的处理
  注意，这里并不包含双方判断大小是否根据手牌进行平局的处理
  这里只是单纯根据7张牌，算出来最大的5张牌即可
  TODO 需要注意的是，因为德州扑克花色不算大小，因此比如4+1的情况，的时候
  单独那个一张，不见得一定是同一花色，要注意
  TODO 现在的算法极为简单粗糙原始，后续可以加以优化改进

  ## 牌型顺序
  * royal_flush
  * straight_flush
  * four_of_a_kind
  * full_house
  * flush
  * straight
  * three_of_a_kind
  * two_pairs
  * pair
  * high_card
  """

  @type hand_type ::
          :royal_flush
          | :straight_flush
          | :four_of_a_kind
          | :full_house
          | :flush
          | :straight
          | :three_of_a_kind
          | :two_pairs
          | :pair
          | :high_card

  @type t :: %__MODULE__{
          type: hand_type(),
          order_key: [pos_integer()],
          best_hand: [Card.t()]
        }

  defstruct [
    # 具体类型，同花顺，葫芦等
    :type,
    # 用来方便比较的key
    :order_key,
    # 最好的5张牌，注意可能并不唯一
    :best_hand
  ]

  @spec run([Card.t()]) :: t()
  def run(hand) do
    checks = [
      &royal_flush?/1,
      &straight_flush?/1,
      &four_of_a_kind?/1,
      &full_house?/1,
      &flush?/1,
      &straight?/1,
      &three_of_a_kind?/1,
      &two_pairs?/1,
      &pair?/1,
      &high_card?/1
    ]

    hand
    |> run_checks(checks)
  end

  @spec all_hand_types() :: [hand_type()]
  def all_hand_types() do
    [
      :royal_flush,
      :straight_flush,
      :four_of_a_kind,
      :full_house,
      :flush,
      :straight,
      :three_of_a_kind,
      :two_pairs,
      :pair,
      :high_card
    ]
  end

  defp run_checks(hand, [f | checks]) do
    case f.(hand) do
      %Ranking{} = result ->
        result

      _ ->
        run_checks(hand, checks)
    end
  end

  defp royal_flush?(_hand) do
    :delegate_to_straight_flush
  end

  defp straight_flush?(hand) do
    cards_by_suit = hand_to_group_by_suit(hand)
    do_straight_flush?(cards_by_suit, Card.all_suits())
  end

  defp do_straight_flush?(_cards, []), do: :not_straight_flush

  defp do_straight_flush?(cards_by_suit, [suit | other_suits]) do
    cards = Map.get(cards_by_suit, suit, [])

    case Enum.count(cards) >= 5 do
      # 7张牌里最多一个花色超过5张
      true ->
        case get_top_straight(cards) do
          nil ->
            :not_straight_flush

          [high_card | _] = cards ->
            case high_card.rank do
              # 皇家同花顺就是TJQKA是同花顺的一种特例而已
              14 ->
                %Ranking{
                  type: :royal_flush,
                  order_key: [],
                  best_hand: cards
                }

              _ ->
                %Ranking{
                  type: :straight_flush,
                  order_key: [high_card.rank],
                  best_hand: cards
                }
            end
        end

      false ->
        do_straight_flush?(cards_by_suit, other_suits)
    end
  end

  # DONE
  defp four_of_a_kind?(hand) do
    case get_top_same_rank(hand, 4) do
      nil ->
        :not_four_of_a_kind

      {[four | _] = four_cards, rest} ->
        best_high_cards = get_top_n_cards(rest, 1)
        high_cards_key = high_cards_order_key(best_high_cards)
        best_hand = pretty_sort_by_suit(four_cards) ++ best_high_cards

        %Ranking{
          type: :four_of_a_kind,
          order_key: [four.rank | high_cards_key],
          best_hand: best_hand
        }
    end
  end

  defp full_house?(hand) do
    case get_top_same_rank(hand, 3) do
      nil ->
        :not_full_house

      {[three | _] = three_cards, rest} ->
        case get_top_same_rank(rest, 2) do
          nil ->
            :not_full_house

          {[two | _] = two_cards, _} ->
            best_hand = pretty_sort_by_suit(three_cards) ++ pretty_sort_by_suit(two_cards)

            %Ranking{
              type: :full_house,
              order_key: [three.rank, two.rank],
              best_hand: best_hand
            }
        end
    end
  end

  defp flush?(hand) do
    cards_by_suit = hand_to_group_by_suit(hand)
    do_flush?(cards_by_suit, Card.all_suits())
  end

  defp do_flush?(_cards, []), do: :not_flush

  defp do_flush?(cards_by_suit, [suit | other_suits]) do
    cards = Map.get(cards_by_suit, suit, [])

    case Enum.count(cards) >= 5 do
      true ->
        best_hand = get_top_n_cards(cards, 5)
        high_cards_key = high_cards_order_key(best_hand)

        %Ranking{
          type: :flush,
          order_key: high_cards_key,
          best_hand: best_hand
        }

      false ->
        do_flush?(cards_by_suit, other_suits)
    end
  end

  defp straight?(hand) do
    case get_top_straight(hand) do
      nil ->
        :not_straight

      [high_card | _] = cards ->
        %Ranking{
          type: :straight,
          order_key: [high_card.rank],
          best_hand: cards
        }
    end
  end

  # DONE
  defp three_of_a_kind?(hand) do
    case get_top_same_rank(hand, 3) do
      nil ->
        :not_three_of_a_kind

      {[three | _] = three_cards, rest} ->
        best_high_cards = get_top_n_cards(rest, 2)
        high_cards_key = high_cards_order_key(best_high_cards)
        best_hand = pretty_sort_by_suit(three_cards) ++ best_high_cards

        %Ranking{
          type: :three_of_a_kind,
          order_key: [three.rank | high_cards_key],
          best_hand: best_hand
        }
    end
  end

  defp two_pairs?(hand) do
    case get_top_same_rank(hand, 2) do
      nil ->
        :not_two_pairs

      {[big_two | _] = big_two_cards, rest} ->
        case get_top_same_rank(rest, 2) do
          nil ->
            :not_two_pairs

          {[small_two | _] = small_two_cards, rest} ->
            [high_card] = get_top_n_cards(rest, 1)

            best_hand =
              pretty_sort_by_suit(big_two_cards) ++
                pretty_sort_by_suit(small_two_cards) ++ [high_card]

            %Ranking{
              type: :two_pairs,
              order_key: [big_two.rank, small_two.rank, high_card.rank],
              best_hand: best_hand
            }
        end
    end
  end

  def pair?(hand) do
    case get_top_same_rank(hand, 2) do
      nil ->
        :not_pair

      {[two | _] = two_cards, rest} ->
        best_high_cards = get_top_n_cards(rest, 3)
        high_cards_key = high_cards_order_key(best_high_cards)
        best_hand = pretty_sort_by_suit(two_cards) ++ best_high_cards

        %Ranking{
          type: :pair,
          order_key: [two.rank | high_cards_key],
          best_hand: best_hand
        }
    end
  end

  defp high_card?(hand) do
    best_hand = get_top_n_cards(hand, 5)
    order_key = high_cards_order_key(best_hand)
    %Ranking{type: :high_card, order_key: order_key, best_hand: best_hand}
  end

  # ======================== 其它辅助函数 =============================
  def pretty_sort_by_suit(cards) do
    Enum.sort_by(cards, fn card -> suit_to_pretty_order(card.suit) end, :desc)
  end

  # 这里，只是显示牌的时候，固定按照黑红梅方的顺序比较好看而已，且测试一致性能够保证
  defp suit_to_pretty_order(:spades), do: 4
  defp suit_to_pretty_order(:hearts), do: 3
  defp suit_to_pretty_order(:clubs), do: 2
  defp suit_to_pretty_order(:diamonds), do: 1

  defp high_cards_order_key(hand) do
    Enum.map(hand, fn card -> card.rank end)
  end

  defp get_top_same_rank(hand, n) do
    cards_by_rank = hand_to_group_by_rank(hand)

    # 采取 >n-1是因为比如取pair的时候，可能是777333这种落选3条的对子情况
    case Enum.split_with(cards_by_rank, fn {_rank, cards} -> Enum.count(cards) > n - 1 end) do
      {[], _} ->
        nil

      {pairs_or_threes, _} ->
        [{_, cards} | _] = Enum.sort(pairs_or_threes, :desc)

        cards =
          cards
          |> pretty_sort_by_suit()
          |> Enum.take(n)

        {cards, hand -- cards}
    end
  end

  defp get_top_n_cards(hand, n) do
    hand
    |> sort_card_by_rank_desc()
    |> Enum.take(n)
  end

  defp hand_to_group_by_rank(hand) do
    Enum.group_by(hand, fn card -> card.rank end)
  end

  defp hand_to_group_by_suit(hand) do
    Enum.group_by(hand, fn card -> card.suit end)
  end

  defp sort_card_by_rank_desc(hand) do
    Enum.sort_by(hand, fn card -> card.rank end, :desc)
  end

  defp get_top_straight(hand) do
    hand
    |> maybe_use_ace_as_one_for_straight_only()
    |> sort_card_by_rank_desc()
    |> try_get_top_straight()
    |> maybe_convert_one_back_to_ace()
  end

  defp maybe_use_ace_as_one_for_straight_only(cards) do
    case get_card_by_rank(cards, 14) do
      %Card{suit: suit, rank: 14} ->
        [%Card{suit: suit, rank: 1} | cards]

      nil ->
        cards
    end
  end

  defp maybe_convert_one_back_to_ace(nil), do: nil

  defp maybe_convert_one_back_to_ace(cards) do
    case Enum.reverse(cards) do
      [%Card{suit: suit, rank: 1} | rest] ->
        Enum.reverse([%Card{suit: suit, rank: 14} | rest])

      _ ->
        cards
    end
  end

  defp try_get_top_straight([high_card | cards]) do
    lower_ranks = 1..4 |> Enum.map(fn x -> high_card.rank - x end)

    case all_ranks_in_hand(lower_ranks, cards) do
      true ->
        [high_card | get_cards_by_ranks(cards, lower_ranks)]

      # 当前最大牌不能凑成5连张
      false ->
        # 剩余牌至少5张才需要验证是否凑成顺子
        case Enum.count(cards) >= 5 do
          true ->
            try_get_top_straight(cards)

          false ->
            nil
        end
    end
  end

  defp all_ranks_in_hand(ranks, cards) do
    Enum.all?(ranks, fn rank -> get_card_by_rank(cards, rank) != nil end)
  end

  defp get_cards_by_ranks(cards, ranks) do
    Enum.map(ranks, fn rank -> get_card_by_rank(cards, rank) end)
  end

  defp get_card_by_rank(cards, rank) do
    Enum.find(cards, fn card -> card.rank == rank end)
  end
end
