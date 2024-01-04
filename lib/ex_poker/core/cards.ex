defmodule ExPoker.Core.Cards do
  alias ExPoker.Core.Card
  alias ExPoker.Core.Ranking

  @spec from_string(String.t()) :: [Card.t()]
  def from_string(str) do
    str
    |> String.split(" ")
    |> Enum.map(&Card.from_string/1)
  end

  @spec sort([Card.t()]) :: [Card.t()]
  def sort(cards) do
    Enum.sort_by(cards, &Card.to_sort_points/1, :desc)
  end

  @spec compare([Card.t()], [Card.t()], [Card.t()]) :: :eq | :gt | :lt
  def compare(cards1, cards2, community_cards) do
    rank1 = Ranking.run(cards1 ++ community_cards)
    rank2 = Ranking.run(cards2 ++ community_cards)

    case compare_ranking_type(rank1.type, rank2.type) do
      :gt ->
        :gt

      :lt ->
        :lt

      :eq ->
        compare_kickers(rank1.kickers, rank2.kickers)
    end
  end

  # 这里最简单的同类型比较，但是四条的时候，比如看手里牌情况没有细致处理暂时
  defp compare_kickers([], []), do: :eq
  defp compare_kickers([c1 | _], [c2 | _]) when c1 > c2, do: :gt
  defp compare_kickers([c1 | _], [c2 | _]) when c1 < c2, do: :lt
  defp compare_kickers([_ | rest1], [_ | rest2]), do: compare_kickers(rest1, rest2)

  defp compare_ranking_type(type1, type2) do
    compare_num(ranking_to_score(type1), ranking_to_score(type2))
  end

  defp ranking_to_score(:royal_flush), do: 100
  defp ranking_to_score(:straight_flush), do: 90
  defp ranking_to_score(:four_of_a_kind), do: 80
  defp ranking_to_score(:full_house), do: 70
  defp ranking_to_score(:flush), do: 60
  defp ranking_to_score(:straight), do: 50
  defp ranking_to_score(:three_of_a_kind), do: 40
  defp ranking_to_score(:two_pairs), do: 30
  defp ranking_to_score(:pair), do: 20
  defp ranking_to_score(:high_card), do: 10

  defp compare_num(a, b) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end
end
