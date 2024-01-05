defmodule ExPoker.MultiplayerGame.PvpTablePlayersTest do
  use ExUnit.Case

  alias ExPoker.MultiplayerGame.PvpTablePlayers

  describe "join_table/4" do
    test "第一个玩家加入牌桌" do
      table = PvpTablePlayers.new(2)
      assert {:ok, table} = PvpTablePlayers.join_table(table, "anna", 500)
      assert table.players[1].pos == 1
      assert table.players[1].username == "anna"
      assert table.players[1].chips == 500
      assert table.players[1].status == :JOINED
    end

    test "第二个玩家加入牌桌分配2号座位" do
      table = PvpTablePlayers.new(2)
      {:ok, table} = PvpTablePlayers.join_table(table, "anna", 500)
      {:ok, table} = PvpTablePlayers.join_table(table, "bobo", 500)

      assert table.players[1].username == "anna"
      assert table.players[2].username == "bobo"
    end

    test "第三个玩家无法加入已满牌桌" do
      table = PvpTablePlayers.new(2)
      {:ok, table} = PvpTablePlayers.join_table(table, "anna", 500)
      {:ok, table} = PvpTablePlayers.join_table(table, "bobo", 500)
      assert {:error, :table_full} == PvpTablePlayers.join_table(table, "cindy", 500)
    end
  end

  describe "players_info/1" do
    test "返回玩家信息" do
      table = PvpTablePlayers.new(2)
      {:ok, table} = PvpTablePlayers.join_table(table, "anna", 500)
      {:ok, table} = PvpTablePlayers.join_table(table, "bobo", 500)

      assert [
               %{pos: 1, username: "anna", chips: 500, status: :JOINED},
               %{pos: 2, username: "bobo", chips: 500, status: :JOINED}
             ] ==
               PvpTablePlayers.players_info(table) |> Enum.sort_by(& &1.pos)
    end
  end

  describe "leave_table/2" do
    test "第一个玩家加入牌桌并离开" do
      table = PvpTablePlayers.new(2)
      {:ok, table} = PvpTablePlayers.join_table(table, "anna", 500)
      assert PvpTablePlayers.player_joined?(table, "anna") == true, "before leave table"
      assert {:ok, 500, _table} = PvpTablePlayers.leave_table(table, "anna")
    end

    test "玩家离开之后可以别人再加入" do
      table = PvpTablePlayers.new(2)
      {:ok, table} = PvpTablePlayers.join_table(table, "anna", 500)
      {:ok, table} = PvpTablePlayers.join_table(table, "bobo", 500)
      {:ok, _, table} = PvpTablePlayers.leave_table(table, "anna")
      assert {:ok, _table} = PvpTablePlayers.join_table(table, "cindy", 500)
    end
  end
end
