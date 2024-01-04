defmodule ExPoker.Core.Deck do
  alias ExPoker.Core.Card

  @type t() :: [Card.t()]

  @spec seq_deck52() :: t()
  def seq_deck52() do
    for rank <- Card.all_ranks() |> Enum.reverse() do
      for suit <- Card.all_suits() do
        {rank, suit}
      end
    end
    |> Enum.concat()
    |> Enum.map(fn {rank, suit} -> Card.new(rank, suit) end)
  end

  @spec shuffle(t()) :: t()
  def shuffle(deck) do
    naive_shuffle(deck)
  end

  defp naive_shuffle(deck) do
    Enum.shuffle(deck)
  end

  @spec take_top_n_cards(t(), pos_integer()) :: {[Card.t()], t()}
  def take_top_n_cards(deck, n) when n > 0 do
    Enum.split(deck, n)
  end
end
