defmodule ExPoker.Core.RankingTest do
  use ExUnit.Case
  alias ExPoker.Core.Hand
  alias ExPoker.Core.Ranking

  defp str2rank(s), do: Hand.from_string(s) |> Ranking.run()

  describe "royal flush" do
    test "皇家同花顺就是同花顺的一种特殊形式" do
      best_hand = Hand.from_string("Ah Kh Qh Jh Th")
      result = "Ah Kh Qh Jh Th 9h 8h" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :royal_flush,
               order_key: [],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "straight flush" do
    test "同花顺基本" do
      best_hand = Hand.from_string("KH QH JH TH 9H")
      result = "KH QH JH TH 9H 8C 7C" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [13],
               best_hand: ^best_hand
             } = result
    end

    test "同花顺优于同花" do
      best_hand = Hand.from_string("JH TH 9H 8H 7H")
      result = "KH JH TH 9H 8H 7H 2C" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [11],
               best_hand: ^best_hand
             } = result
    end

    test "同花顺优于顺子" do
      best_hand = Hand.from_string("JH TH 9H 8H 7H")
      result = "QC JH TH 9H 8H 7H 2C" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [11],
               best_hand: ^best_hand
             } = result
    end

    test "同花顺最大张需要连续到5张相连" do
      best_hand = Hand.from_string("JH TH 9H 8H 7H")
      result = "AH KH JH TH 9H 8H 7H" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [11],
               best_hand: ^best_hand
             } = result
    end

    test "同花顺最大就是9TJQK了" do
      best_hand = Hand.from_string("KH QH JH TH 9H")
      result = "KH QH JH TH 9H 8H 7H" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [13],
               best_hand: ^best_hand
             } = result
    end

    test "A2345也是同花顺" do
      best_hand = Hand.from_string("5H 4H 3H 2H AH")
      result = "5H 4H 3H 2H AH AD AC" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [5],
               best_hand: ^best_hand
             } = result
    end

    test "A2345是最小的同花顺" do
      best_hand = Hand.from_string("6H 5H 4H 3H 2H")
      result = "5H 4H 3H 2H AH 6H AC" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight_flush,
               order_key: [6],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "four of a kind" do
    test "四条基础" do
      best_hand = Hand.from_string("2S 2H 2C 2D AH")
      result = "2S 2C 2H 2D 9H AH 7S" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :four_of_a_kind,
               order_key: [2, 14],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "full house" do
    test "葫芦基础" do
      best_hand = Hand.from_string("2S 2H 2C AH AD")
      result = "2S 2C 2H 7C AH AD 6H" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :full_house,
               order_key: [2, 14],
               best_hand: ^best_hand
             } = result
    end

    test "两个三条之间取大的那个" do
      best_hand = Hand.from_string("7S 7H 7C 2S 2H")
      result = "2S 2C 2H 7S 7C 7H 6H" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :full_house,
               order_key: [7, 2],
               best_hand: ^best_hand
             } = result

      best_hand = Hand.from_string("7S 7H 7C 2S 2H")
      result = "2S 7S 7C 2C 2H 7H 6H" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :full_house,
               order_key: [7, 2],
               best_hand: ^best_hand
             } = result
    end

    test "额外两个对子的话取大的" do
      best_hand = Hand.from_string("2S 2H 2C AH AD")
      result = "2S 2C 2H 7C AH AD 7H" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :full_house,
               order_key: [2, 14],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "flush" do
    test "同花基础" do
      best_hand = Hand.from_string("7H 5H 4H 3H 2H")
      result = "2H 3H 4H 5H 7H AD KD" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :flush,
               order_key: [7, 5, 4, 3, 2],
               best_hand: ^best_hand
             } = result
    end

    test "同花优先于一些后续牌型" do
      best_hand = Hand.from_string("AH 6H 4H 3H 2H")
      result = "2H 3H 4H 6H AH AD AC" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :flush,
               order_key: [14, 6, 4, 3, 2],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "straight" do
    test "顺子基础" do
      best_hand = Hand.from_string("6C 5H 4H 3H 2H")
      result = "2H 3H 4H 5H 6C AD KD" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight,
               order_key: [6],
               best_hand: ^best_hand
             } = result
    end

    test "A2345也是顺子" do
      best_hand = Hand.from_string("5H 4H 3H 2H AC")
      result = "2H 3H 4H 5H AC AD KD" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight,
               order_key: [5],
               best_hand: ^best_hand
             } = result
    end

    test "并且A2345是最小的顺子" do
      best_hand = Hand.from_string("6C 5H 4H 3H 2H")
      result = "AC 2H 3H 4H 5H 6C AD" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :straight,
               order_key: [6],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "three of a kind" do
    test "三条基础" do
      best_hand = Hand.from_string("2S 2H 2C AH QS")
      result = "2S 2C 2H 8D 9H AH QS" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :three_of_a_kind,
               order_key: [2, 14, 12],
               best_hand: ^best_hand
             } = result
    end
  end

  describe "two pairs" do
    test "两对基础" do
      best_hand = Hand.from_string("AS AD QS QH KH")
      result = "AS AD QS QH KH 3C 2C" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :two_pairs,
               order_key: [14, 12, 13],
               best_hand: ^best_hand
             } = result
    end

    test "三对的话挑最大的两对" do
      # 三对的话，最后只能取一张的情况下花色就不确定了
      best_hand1 = Hand.from_string("AS AD KH KC QS")
      best_hand2 = Hand.from_string("AS AD KH KC QH")
      result = "AS AD QH QS KH KC 2C" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :two_pairs,
               order_key: [14, 13, 12],
               best_hand: best_hand
             } = result

      assert best_hand1 == best_hand or best_hand2 == best_hand
    end
  end

  describe "pair" do
    test "对子基础" do
      best_hand = Hand.from_string("AS AD QS JH 9H")
      result = "AS AD QS JH 9H 3C 2C" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :pair,
               order_key: [14, 12, 11, 9],
               best_hand: ^best_hand
             } = result
    end

    test "对子无论大小都排在单张的前边" do
      best_hand = Hand.from_string("2S 2D QS JH 9H")
      result = "QS JH 9H 7C 5S 2S 2D" |> Hand.from_string() |> Ranking.run()

      assert %Ranking{
               type: :pair,
               order_key: [2, 12, 11, 9],
               best_hand: ^best_hand
             } = result
    end
  end

  test "high card" do
    best_hand = Hand.from_string("AS KS QS JH 9H")

    assert %Ranking{
             type: :high_card,
             order_key: [14, 13, 12, 11, 9],
             best_hand: ^best_hand
           } = "AS KS QS JH 9H 3C 2C" |> str2rank()
  end
end
