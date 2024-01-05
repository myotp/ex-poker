defmodule ExPoker.MultiplayerGame.PvpTablePlayers do
  defstruct [
    :max_players,
    :players
  ]

  defmodule Player do
    defstruct [:pos, :username, :chips, :status]
  end

  def new(max_players) do
    %__MODULE__{max_players: max_players, players: %{}}
  end

  def join_table(%__MODULE__{} = state, username, buyin) do
    case player_joined?(state, username) do
      true ->
        {:error, :user_already_joined}

      false ->
        case first_free_pos(state) do
          nil ->
            {:error, :table_full}

          pos ->
            {:ok,
             put_in(state.players[pos], %Player{
               pos: pos,
               username: username,
               chips: buyin,
               status: :JOINED
             })}
        end
    end
  end

  def start_game(%__MODULE__{} = state, username) do
    case find_player_by_username(state, username) do
      %Player{pos: pos} ->
        {:ok, put_in(state.players[pos].status, :WAITING)}
    end
  end

  def leave_table(%__MODULE__{players: players} = state, username) do
    case find_player_by_username(state, username) do
      %Player{pos: pos, chips: chips} ->
        {:ok, chips, %__MODULE__{state | players: Map.delete(players, pos)}}

      nil ->
        {:error, :player_not_on_table}
    end
  end

  def players_info(%__MODULE__{players: players}) do
    players
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Map.from_struct/1)
  end

  def player_joined?(%__MODULE__{} = state, username) do
    state
    |> find_player_by_username(username)
    |> case do
      %Player{} -> true
      _ -> false
    end
  end

  defp first_free_pos(%__MODULE__{max_players: max_players, players: players}) do
    1..max_players
    |> Enum.drop_while(fn pos -> is_map(players[pos]) end)
    |> Enum.at(0)
  end

  defp find_player_by_username(%__MODULE__{players: players}, username) do
    players
    |> Map.values()
    |> Enum.find(fn p -> p.username == username end)
  end
end
