defmodule ExPoker.MultiplayerGame.Table do
  @moduledoc """
  API module for table_server
  """

  @spec join_table(pid(), String.t(), pos_integer() | nil) :: :ok | {:error, any()}
  def join_table(pid, username, buyin \\ nil) do
    GenServer.call(pid, {:join_table, username, buyin, self()})
  end

  @spec leave_table(pid(), String.t()) :: :ok
  def leave_table(pid, username) do
    GenServer.call(pid, {:leave_table, username})
  end

  @spec start_game(pid(), String.t()) :: :ok
  def start_game(pid, username) do
    GenServer.call(pid, {:start_game, username})
  end

  @type player_action :: :fold | :check | :call | {:raise, pos_integer()}
  @spec handle_username_action(pid(), String.t(), player_action()) :: :ok
  def handle_username_action(pid, username, action) do
    GenServer.call(pid, {:handle_player_action, username, action})
  end
end
