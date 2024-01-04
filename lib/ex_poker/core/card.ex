defmodule ExPoker.Core.Card do
  @moduledoc """
  扑克游戏当中核心纸牌Card表示

  ## 单一纸牌的表示方法
   * 内部表示法，点数rank用数字2-14表示，suit为atom比如♥️A表示为 %Card{rank: 14, suit: :hearts}
   * 一种表示法为字符串，比如♥️A表示为"ah"这种表示法用来一般网络传输序列化以及一般性输入
   * 一种emoji表示法，为带有实际♠️♥️♣️♦️的表示法，用来实现自己命令行程序的时候，输出比较好看，比如♥️K
  """
  alias __MODULE__

  @spades :spades
  @hearts :hearts
  @clubs :clubs
  @diamonds :diamonds

  @type rank :: 2..14
  @type suit :: :spades | :hearts | :clubs | :diamonds
  @type t :: %__MODULE__{
          rank: rank(),
          suit: suit()
        }
  defstruct [:rank, :suit]

  @spec all_suits() :: [:clubs | :diamonds | :hearts | :spades]
  def all_suits() do
    [@spades, @hearts, @clubs, @diamonds]
  end

  @spec all_ranks() :: list(rank())
  def all_ranks() do
    Enum.to_list(2..14)
  end

  @spec from_string(String.t()) :: ExPoker.Core.Card.t()
  def from_string(str) do
    [rank_str, suit_str] =
      str
      |> String.codepoints()

    new(string_to_rank(rank_str), string_to_suit(String.downcase(suit_str)))
  end

  def string_to_rank("T"), do: 10
  def string_to_rank("J"), do: 11
  def string_to_rank("Q"), do: 12
  def string_to_rank("K"), do: 13
  def string_to_rank("A"), do: 14
  def string_to_rank(s), do: String.to_integer(s)

  defp string_to_suit("s"), do: @spades
  defp string_to_suit("h"), do: @hearts
  defp string_to_suit("c"), do: @clubs
  defp string_to_suit("d"), do: @diamonds

  @spec new(2..14, :clubs | :diamonds | :hearts | :spades) :: ExPoker.Core.Card.t()
  def new(rank, suit) when rank in 2..14 and suit in [:spades, :hearts, :clubs, :diamonds] do
    %Card{rank: rank, suit: suit}
  end

  def to_string(%Card{rank: rank, suit: suit}) do
    "#{rank_to_string(rank)}#{suit_to_string(suit)}"
  end

  def to_emoji_string(%Card{rank: rank, suit: suit}) do
    "#{suit_to_emoji_string(suit)}#{rank_to_emoji_string(rank)}"
  end

  defp rank_to_string(14), do: "A"
  defp rank_to_string(13), do: "K"
  defp rank_to_string(12), do: "Q"
  defp rank_to_string(11), do: "J"
  defp rank_to_string(10), do: "T"
  defp rank_to_string(r) when r >= 2 and r <= 9, do: "#{r}"

  defp rank_to_emoji_string(10), do: "10"
  defp rank_to_emoji_string(r), do: rank_to_string(r)

  defp suit_to_string(@hearts), do: "h"
  defp suit_to_string(@spades), do: "s"
  defp suit_to_string(@clubs), do: "c"
  defp suit_to_string(@diamonds), do: "d"

  defp suit_to_emoji_string(@spades), do: "♠️"
  defp suit_to_emoji_string(@hearts), do: "♥️"
  defp suit_to_emoji_string(@clubs), do: "♣️"
  defp suit_to_emoji_string(@diamonds), do: "♦️"

  @spec to_sort_points(ExPoker.Core.Card.t()) :: pos_integer()
  def to_sort_points(%Card{rank: rank, suit: suit}) do
    rank * 4 + suit_to_sort_points(suit)
  end

  defp suit_to_sort_points(:spades), do: 3
  defp suit_to_sort_points(:hearts), do: 2
  defp suit_to_sort_points(:clubs), do: 1
  defp suit_to_sort_points(:diamonds), do: 0
end

defimpl Inspect, for: SuperPoker.Core.Card do
  # 这里之后，再具体看细致的opts的处理方法
  def inspect(card, _opts) do
    ExPoker.Core.Card.to_emoji_string(card)
  end
end

defimpl String.Chars, for: SuperPoker.Core.Card do
  def to_string(card) do
    ExPoker.Core.Card.to_string(card)
  end
end
