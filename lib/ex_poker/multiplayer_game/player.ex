defmodule ExPoker.MultiplayerGame.Player do
  def broadcast_players_info(pid, players_info) do
    GenServer.cast(pid, {:players_info, players_info})
  end
end
