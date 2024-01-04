defmodule ExPoker.Core.CardsTest do
  use ExUnit.Case

  alias ExPoker.Core.Card
  alias ExPoker.Core.Cards

  describe "from_string/1" do
    test "string to hand" do
      assert [%Card{rank: 14}, %Card{rank: 13}] = Cards.from_string("Ah Kh")
    end
  end

  describe "sort/1" do
    test "sort cards in a hand" do
      assert [
               %Card{rank: 14, suit: :spades},
               %Card{rank: 14, suit: :diamonds},
               %Card{rank: 13, suit: :hearts},
               %Card{rank: 13, suit: :clubs}
             ] ==
               "Kh Ad Kc As"
               |> Cards.from_string()
               |> Cards.sort()
    end
  end

  describe "compare/3" do
    test "不同牌型之间比较" do
      cards1 = Cards.from_string("Ah Kh")
      community_cards = Cards.from_string("Qh Jh Th 2s 2d")
      cards2 = Cards.from_string("7h 8h")
      assert Cards.compare(cards1, cards2, community_cards) == :gt
      assert Cards.compare(cards2, cards1, community_cards) == :lt
    end

    test "同样葫芦优先看三张的大小" do
      cards1 = Cards.from_string("AH AS")
      community_cards = Cards.from_string("AD JH TH 2S 2D")
      cards2 = Cards.from_string("2H TD")
      assert Cards.compare(cards1, cards2, community_cards) == :gt
    end

    test "单对优先比对子本身大小" do
      cards1 = Cards.from_string("9H KS")
      community_cards = Cards.from_string("QS 9D 5S 4H 2D")
      cards2 = Cards.from_string("5D AH")
      assert Cards.compare(cards1, cards2, community_cards) == :gt
    end

    test "对子一样的时候比第一个大踢脚" do
      cards1 = Cards.from_string("AH KS")
      community_cards = Cards.from_string("AS 9D 5S 4H 2D")
      cards2 = Cards.from_string("AD QH")
      assert Cards.compare(cards1, cards2, community_cards) == :gt
    end

    test "对子与第一踢脚相同时候比第二踢脚" do
      cards1 = Cards.from_string("AH QS")
      community_cards = Cards.from_string("AS KH 5S 4H 2D")
      cards2 = Cards.from_string("AD JD")
      assert Cards.compare(cards1, cards2, community_cards) == :gt
    end
  end
end
