defmodule ExPoker.MultiplayerGame.Player do
  def broadcast_players_info(pid, players_info) do
    GenServer.cast(pid, {:players_info, players_info})
  end

  def broadcast_game_started(pid, players_info) do
    GenServer.cast(pid, {:game_started, players_info})
  end

  def broadcast_bets_info(pid, {bets_info, last_action}) do
    GenServer.cast(pid, {:bets_info, {bets_info, last_action}})
  end
end
