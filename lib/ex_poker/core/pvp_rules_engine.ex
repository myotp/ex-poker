defmodule ExPoker.Core.PvpRulesEngine do
  @moduledoc """
  牌局进行中规则引擎

  * 上层需要处理button位置正确
  * 对于大小盲, 需要上层处理确认玩家有足够盲注金额下注
  """

  defmodule Player do
    defstruct [
      :username,
      :chips_left,
      :current_street_bet
    ]
  end

  defmodule State do
    defstruct [
      :street,
      :players,
      :button,
      :players_order,
      :next_action,
      next_player: nil,
      first_player: nil,
      pot: 0,
      current_call_amount: 0
    ]

    @type username :: String.t()
    @type street :: :preflop | :flop | :turn | :river
    @type table_action ::
            {:table, {:deal, street()}} | {:table, {:show_hands, pot :: non_neg_integer(), map()}}
    @type player_action_options ::
            :fold | :check | {:call, non_neg_integer()} | {:raise, non_neg_integer()}
    @type player_action :: {:player, username(), player_action_options()}
    @type winner_result :: {:winner, username(), chips_info :: map()}
    @type t :: %__MODULE__{
            street: street(),
            players: map(),
            button: username(),
            players_order: list(username()),
            next_action: table_action() | player_action() | winner_result(),
            next_player: nil | username(),
            first_player: nil | username(),
            pot: non_neg_integer(),
            current_call_amount: non_neg_integer()
          }
  end

  @type username :: String.t()
  @spec new(
          players_info :: list({username(), non_neg_integer()}),
          button_player :: username(),
          Enum.t({username(), non_neg_integer()})
        ) :: State.t()
  def new(players_info, button_player, blinds) do
    players_order = Enum.map(players_info, fn {username, _} -> username end)

    %State{
      button: button_player,
      players_order: players_order,
      players: create_players(players_info)
    }
    |> set_street(:preflop)
    |> reset_call_amount()
    |> reset_first_and_next_player()
    |> make_blinds_bets(blinds)
    |> set_next_action()
  end

  @type street :: :preflop | :flop | :turn | :river
  @spec handle_table_action(State.t(), {:done, street()}) :: State.t()
  def handle_table_action(%State{} = state, {:done, street}) do
    state
    |> set_street(street)
    |> reset_call_amount()
    |> reset_first_and_next_player()
    |> set_next_action()
  end

  defp reset_call_amount(%State{} = state) do
    %State{state | current_call_amount: 0}
  end

  @type player_action :: :fold | :check | :call | {:raise, non_neg_integer()}
  @spec handle_player_action(State.t(), String.t(), player_action()) :: State.t()
  def handle_player_action(%State{} = state, username, :call) do
    amount_to_call = state.current_call_amount - state.players[username].current_street_bet

    state
    |> make_player_bet(username, amount_to_call)
    |> maybe_set_first_player(username, :call)
    |> set_next_player(username)
    |> set_next_action()
  end

  def handle_player_action(%State{} = state, username, :check) do
    state
    |> maybe_set_first_player(username, :check)
    |> set_next_player(username)
    |> set_next_action()
  end

  def handle_player_action(%State{} = state, username, {:raise, amount}) do
    state
    |> make_player_bet(username, amount)
    |> maybe_set_first_player(username, :raise)
    |> set_next_player(username)
    |> set_next_action()
  end

  def handle_player_action(%State{players_order: players_order} = state, username, :fold) do
    winner = next_player(players_order, username)

    # 二人对战, 其中一人fold另外一人自动获胜
    state = move_bets_to_pot(state)

    chips_left =
      players_chips_left(state)
      |> Map.update!(winner, fn chips -> chips + state.pot end)

    %State{state | next_action: {:winner, winner, chips_left}}
  end

  defp set_next_player(%State{} = state, username) do
    %State{state | next_player: next_player(state.players_order, username)}
  end

  defp next_player(players_order, username) do
    Enum.concat(players_order, players_order)
    |> Enum.drop_while(&(&1 != username))
    |> Enum.drop(1)
    |> hd()
  end

  defp prev_player(players_order, username) do
    reversed_order = Enum.reverse(players_order)

    Enum.concat(reversed_order, reversed_order)
    |> Enum.drop_while(&(&1 != username))
    |> Enum.drop(1)
    |> hd()
  end

  # 之前还没有任何玩家行动过
  defp maybe_set_first_player(%State{first_player: nil} = state, username, _player_action) do
    %State{state | first_player: username}
  end

  # 玩家raise的话, 之前已行动玩家需要重新行动一次
  defp maybe_set_first_player(%State{} = state, username, :raise) do
    %State{state | first_player: username}
  end

  # 除raise以外的fold,check,call不改变最终玩家位置
  defp maybe_set_first_player(%State{} = state, _username, _player_action) do
    state
  end

  # 之前还没有任何玩家行动过
  defp set_next_action(%State{first_player: nil} = state) do
    set_next_player_action(state)
  end

  # 继续其他玩家行动
  defp set_next_action(%State{first_player: first_player, next_player: next_player} = state)
       when first_player != next_player do
    set_next_player_action(state)
  end

  # 当再次回到first_player的时候, 此轮结束
  defp set_next_action(%State{first_player: first_player, next_player: next_player} = state)
       when first_player == next_player do
    set_next_table_action(state)
  end

  defp set_next_table_action(state) do
    state = move_bets_to_pot(state)

    case state.street do
      :preflop ->
        %State{state | next_action: {:table, {:deal, :flop}}}

      :flop ->
        %State{state | next_action: {:table, {:deal, :turn}}}

      :turn ->
        %State{state | next_action: {:table, {:deal, :river}}}

      :river ->
        %State{state | next_action: {:table, {:show_hands, state.pot, players_chips_left(state)}}}
    end
  end

  defp players_chips_left(%State{players: players}) do
    Enum.into(players, %{}, fn {username, p} -> {username, p.chips_left} end)
  end

  defp set_next_player_action(%State{next_player: username} = state) do
    player_already_bet = state.players[username].current_street_bet
    action_options = player_action_options(player_already_bet, state.current_call_amount)
    %State{state | next_action: {:player, {username, action_options}}}
  end

  # 玩家已经下注满足当前call数量,开局大盲适用,或者首位行动玩家, 这里简化版对战规则刻意做了几点简化
  # 1. allin现在不处理, 即不考虑玩家筹码不足的情况
  # 2. 不考虑复杂下注规则，比如限制倍数
  # 3. raise任意数量，并且假设是在满足call的之后的数量
  defp player_action_options(player_bet, call_amount) when player_bet == call_amount do
    [:fold, :check, :raise]
  end

  defp player_action_options(player_bet, call_amount) do
    [:fold, {:call, call_amount - player_bet}, :raise]
  end

  defp set_street(state, street) when street in [:preflop, :flop, :river, :turn] do
    %State{state | street: street}
  end

  defp create_players(players_info) do
    Enum.reduce(players_info, %{}, fn {username, chips}, acc ->
      player = %Player{
        username: username,
        current_street_bet: 0,
        chips_left: chips
      }

      Map.put(acc, username, player)
    end)
  end

  defp make_blinds_bets(state, blinds) do
    Enum.reduce(blinds, state, fn {username, amount}, acc_state ->
      make_player_bet(acc_state, username, amount)
    end)
  end

  defp make_player_bet(
         %State{
           players: players,
           current_call_amount: current_call_amount
         } = state,
         username,
         amount
       ) do
    player =
      %Player{chips_left: chips_left, current_street_bet: current_street_bet} = players[username]

    updated_player = %Player{
      player
      | chips_left: chips_left - amount,
        current_street_bet: current_street_bet + amount
    }

    current_call_amount =
      if current_street_bet + amount > current_call_amount do
        current_street_bet + amount
      else
        current_call_amount
      end

    players = Map.put(players, username, updated_player)

    %State{
      state
      | current_call_amount: current_call_amount,
        players: players
    }
  end

  # 双人对战preflop从button(小盲)开始行动
  def reset_first_and_next_player(%State{street: :preflop, button: button} = state) do
    %State{state | next_player: button, first_player: nil}
  end

  # flop之后都是button最后行动
  def reset_first_and_next_player(%State{players_order: players_order, button: button} = state) do
    player_before_button = prev_player(players_order, button)
    %State{state | next_player: player_before_button, first_player: nil}
  end

  def move_bets_to_pot(%State{players: players, pot: pot} = state) do
    total_bets =
      get_in(Map.values(players), [Access.all(), Access.key(:current_street_bet)])
      |> Enum.sum()

    new_players =
      Enum.reduce(players, %{}, fn {username, player}, acc ->
        Map.put(acc, username, %Player{player | current_street_bet: 0})
      end)

    %State{state | pot: pot + total_bets, players: new_players}
  end
end
