defmodule ExPoker.MultiplayerGame.PvpTableServer do
  use GenServer

  alias ExPoker.Core.PvpGameEngine
  alias ExPoker.MultiplayerGame.TableConfig
  alias ExPoker.MultiplayerGame.PvpTable
  alias ExPoker.MultiplayerGame.Player

  @type t :: %__MODULE__{
          table_config: TableConfig.t(),
          table: PvpTable.t(),
          game_engine: PvpGameEngine.t(),
          user_pids: map(),
          button_pos: pos_integer()
        }
  defstruct [
    :table_config,
    :table,
    :game_engine,
    :user_pids,
    button_pos: 1
  ]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    table_config = TableConfig.new!(args)
    table = PvpTable.new(args[:max_players])
    {:ok, %__MODULE__{table_config: table_config, table: table, user_pids: %{}}}
  end

  @impl GenServer
  def handle_call(
        {:join_table, username, buyin, client_pid},
        _from,
        %__MODULE__{table: table, user_pids: user_pids} = state
      ) do
    buyin = buyin || state.table_config.buyin

    case PvpTable.join_table(table, username, buyin) do
      {:ok, updated_table} ->
        new_state =
          state
          |> Map.put(:user_pids, Map.put(user_pids, username, client_pid))
          |> update_table(updated_table)

        {:reply, :ok, new_state}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:leave_table, username}, _from, %__MODULE__{user_pids: user_pids} = state) do
    case PvpTable.leave_table(state.table, username) do
      {:ok, chips_left, updated_table} ->
        new_state =
          state
          |> Map.put(:user_pids, Map.delete(user_pids, username))
          |> update_table(updated_table)

        {:reply, {:ok, chips_left}, new_state}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:start_game, username},
        _from,
        %__MODULE__{table: table} = state
      ) do
    case PvpTable.start_game(table, username) do
      {:ok, updated_table} ->
        new_state = update_table(state, updated_table)
        {:reply, :ok, new_state, {:continue, :maybe_table_start_game}}
    end
  end

  @impl GenServer
  def handle_continue(:maybe_table_start_game, %__MODULE__{table: table} = state) do
    case PvpTable.can_table_start_game?(table) do
      true ->
        broadcast_game_started(state)
        {:noreply, state, {:continue, :do_table_start_game}}

      false ->
        {:noreply, state}
    end
  end

  def handle_continue(
        :do_table_start_game,
        %__MODULE__{button_pos: button_pos, table_config: cfg} = state
      ) do
    players_info = PvpTable.players_info(state.table)
    game_engine = PvpGameEngine.new(players_info, button_pos, {cfg.sb, cfg.bb})
    state = %__MODULE__{state | game_engine: game_engine}
    broadcast_bets_info(state, :blinds)
    {:noreply, state}
  end

  defp update_table(state, updated_table) do
    new_state = %__MODULE__{state | table: updated_table}
    broadcast_players_info(new_state)
    new_state
  end

  defp broadcast_players_info(%__MODULE__{user_pids: user_pids, table: table}) do
    players_info = PvpTable.players_info(table)

    user_pids
    |> Map.values()
    |> Enum.each(fn pid -> Player.broadcast_players_info(pid, players_info) end)
  end

  defp broadcast_game_started(%__MODULE__{user_pids: user_pids, table: table}) do
    players_info = PvpTable.players_info(table)

    user_pids
    |> Map.values()
    |> Enum.each(fn pid -> Player.broadcast_game_started(pid, players_info) end)
  end

  defp broadcast_bets_info(
         %__MODULE__{user_pids: user_pids, game_engine: game_engine},
         last_action
       ) do
    bets_info = PvpGameEngine.bets_info(game_engine)

    user_pids
    |> Map.values()
    |> Enum.each(fn pid -> Player.broadcast_bets_info(pid, {bets_info, last_action}) end)
  end
end
