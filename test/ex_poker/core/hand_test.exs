defmodule ExPoker.Core.HandTest do
  use ExUnit.Case
  alias ExPoker.Core.Hand
  alias ExPoker.Core.Card

  describe "from_string/1" do
    test "string to hand" do
      assert [%Card{rank: 14}, %Card{rank: 13}] = Hand.from_string("Ah Kh")
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
               |> Hand.from_string()
               |> Hand.sort()
    end
  end
end
