# TODO: HandHistory功能直接进入此模块
defmodule ExPoker.Core.PvpGameEngine do
  alias ExPoker.Core.PvpRulesEngine
  alias ExPoker.Core.HandHistory

  @type t :: %__MODULE__{
          rules_engine: ExPoker.Core.PvpRulesEngine.t(),
          hand_history: ExPoker.Core.HandHistory.t()
        }
  defstruct [
    :rules_engine,
    :hand_history
  ]

  @spec new(
          [%{pos: pos_integer(), username: String.t(), chips: pos_integer()}],
          pos_integer(),
          {pos_integer(), pos_integer()}
        ) ::
          ExPoker.Core.PvpGameEngine.t()

  def new(players, button_pos, {sb, bb}) do
    blinds = decide_blinds(players, button_pos, {sb, bb})
    hand_history = HandHistory.new(players, button_pos, {sb, bb}, blinds)
    players_info = players_info_for_rules_engine(players, button_pos)
    button_player = find_player_by_pos(players, button_pos)
    rules_engine = PvpRulesEngine.new(players_info, button_player.username, blinds)
    %__MODULE__{hand_history: hand_history, rules_engine: rules_engine}
  end

  @spec bets_info(ExPoker.Core.PvpGameEngine.t()) :: %{
          :pot => non_neg_integer(),
          String.t() => %{chips_left: non_neg_integer(), current_street_bet: non_neg_integer()}
        }
  def bets_info(%__MODULE__{rules_engine: rules_engine}) do
    PvpRulesEngine.bets_info(rules_engine)
  end

  defp players_info_for_rules_engine(players, button_pos) do
    [button_pos, next_pos(button_pos)]
    |> Enum.map(fn pos -> find_player_by_pos(players, pos) end)
    |> Enum.map(fn p -> {p.username, p.chips} end)
  end

  # 只有两个玩家的时候，约定sb为button位置
  defp decide_blinds(players, button_pos, {sb_amount, bb_amount}) do
    sb_pos = button_pos
    bb_pos = next_pos(button_pos)

    sb_player = find_player_by_pos(players, sb_pos)
    bb_player = find_player_by_pos(players, bb_pos)
    [{sb_player.username, sb_amount}, {bb_player.username, bb_amount}]
  end

  defp find_player_by_pos(players, pos) do
    Enum.find(players, fn p -> p.pos == pos end)
  end

  defp next_pos(1), do: 2
  defp next_pos(2), do: 1

  @type username :: String.t()
  @type street :: :preflop | :flop | :turn | :river
  @type table_action ::
          {:table, {:deal, street()}} | {:table, {:show_hands, pot :: non_neg_integer(), map()}}
  @type player_action_options ::
          :fold | :check | {:call, non_neg_integer()} | {:raise, non_neg_integer()}
  @type player_action :: {:player, username(), player_action_options()}
  @type winner_result :: {:winner, username(), chips_info :: map()}
  @spec next_action(ExPoker.Core.PvpGameEngine.t()) ::
          player_action() | table_action() | winner_result()
  def next_action(%__MODULE__{} = game_engine) do
    game_engine.rules_engine.next_action
  end
end
