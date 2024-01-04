defmodule ExPoker.Core.CardTest do
  use ExUnit.Case
  alias ExPoker.Core.Card

  describe "to_string/1" do
    test "数字在前, JQKA用大写, 花色在后, 用小写" do
      assert "As" == Card.to_string(%Card{rank: 14, suit: :spades})
      assert "Kh" == Card.to_string(%Card{rank: 13, suit: :hearts})
      assert "Qc" == Card.to_string(%Card{rank: 12, suit: :clubs})
      assert "Jd" == Card.to_string(%Card{rank: 11, suit: :diamonds})
      assert "Ts" == Card.to_string(%Card{rank: 10, suit: :spades})
      assert "9h" == Card.to_string(%Card{rank: 9, suit: :hearts})
    end
  end

  describe "to_emoji_string/1" do
    test "花色在前, 数字在后, 10就是10" do
      assert "♠️A" == Card.to_emoji_string(%Card{rank: 14, suit: :spades})
      assert "♥️K" == Card.to_emoji_string(%Card{rank: 13, suit: :hearts})
      assert "♣️Q" == Card.to_emoji_string(%Card{rank: 12, suit: :clubs})
      assert "♦️J" == Card.to_emoji_string(%Card{rank: 11, suit: :diamonds})
      assert "♥️10" == Card.to_emoji_string(%Card{rank: 10, suit: :hearts})
      assert "♥️9" == Card.to_emoji_string(%Card{rank: 9, suit: :hearts})
    end
  end

  describe "from_string/1" do
    test "数字在前, 花色在后, 正常是小写" do
      assert %Card{rank: 14, suit: :spades} == Card.from_string("As")
      assert %Card{rank: 13, suit: :hearts} == Card.from_string("Kh")
      assert %Card{rank: 12, suit: :clubs} == Card.from_string("Qc")
      assert %Card{rank: 11, suit: :diamonds} == Card.from_string("Jd")
      assert %Card{rank: 10, suit: :spades} == Card.from_string("Ts")
      assert %Card{rank: 9, suit: :hearts} == Card.from_string("9h")
    end

    test "花色可以接受大写字母表示" do
      assert %Card{rank: 14, suit: :spades} == Card.from_string("AS")
      assert %Card{rank: 13, suit: :hearts} == Card.from_string("KH")
    end
  end
end
