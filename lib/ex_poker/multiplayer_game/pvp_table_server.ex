defmodule ExPoker.MultiplayerGame.PvpTableServer do
  use GenServer

  alias ExPoker.MultiplayerGame.TableConfig
  alias ExPoker.MultiplayerGame.PvpTablePlayers
  alias ExPoker.MultiplayerGame.Player

  defstruct [
    :table_config,
    :players,
    :user_pids
  ]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    table_config = TableConfig.new!(args)
    players = PvpTablePlayers.new(args[:max_players])
    {:ok, %__MODULE__{table_config: table_config, players: players, user_pids: %{}}}
  end

  @impl GenServer
  def handle_call(
        {:join_table, username, buyin, client_pid},
        _from,
        %__MODULE__{players: players, user_pids: user_pids} = state
      ) do
    buyin = buyin || state.table_config.buyin

    case PvpTablePlayers.join_table(players, username, buyin) do
      {:ok, updated_players} ->
        new_state =
          state
          |> Map.put(:user_pids, Map.put(user_pids, username, client_pid))
          |> update_table_players(updated_players)

        {:reply, :ok, new_state}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:leave_table, username}, _from, %__MODULE__{user_pids: user_pids} = state) do
    case PvpTablePlayers.leave_table(state.players, username) do
      {:ok, chips_left, updated_players} ->
        new_state =
          state
          |> Map.put(:user_pids, Map.delete(user_pids, username))
          |> update_table_players(updated_players)

        {:reply, {:ok, chips_left}, new_state}

      {:error, _reason} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:start_game, username},
        _from,
        %__MODULE__{players: players} = state
      ) do
    case PvpTablePlayers.start_game(players, username) do
      {:ok, updated_players} ->
        new_state = update_table_players(state, updated_players)
        {:reply, :ok, new_state}
    end
  end

  defp update_table_players(state, updated_players) do
    new_state = %__MODULE__{state | players: updated_players}
    broadcast_players_info(new_state)
    new_state
  end

  defp broadcast_players_info(%__MODULE__{user_pids: user_pids, players: players}) do
    players_info = PvpTablePlayers.players_info(players)

    user_pids
    |> Map.values()
    |> Enum.each(fn pid -> Player.broadcast_players_info(pid, players_info) end)
  end
end
