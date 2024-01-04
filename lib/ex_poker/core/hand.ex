defmodule ExPoker.Core.Hand do
  alias ExPoker.Core.Card

  @spec from_string(String.t()) :: [Card.t()]
  def from_string(str) do
    str
    |> String.split(" ")
    |> Enum.map(&Card.from_string/1)
  end

  def sort(hand) do
    Enum.sort_by(hand, &Card.to_sort_points/1, :desc)
  end
end
