defmodule ExPoker.MultiplayerGame.PvpTableTest do
  use ExUnit.Case

  alias ExPoker.MultiplayerGame.PvpTable

  describe "join_table/4" do
    test "第一个玩家加入牌桌" do
      table = PvpTable.new(2)
      assert {:ok, table} = PvpTable.join_table(table, "anna", 500)
      assert table.players[1].pos == 1
      assert table.players[1].username == "anna"
      assert table.players[1].chips == 500
      assert table.players[1].status == :JOINED
    end

    test "第二个玩家加入牌桌分配2号座位" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      {:ok, table} = PvpTable.join_table(table, "bobo", 500)

      assert table.players[1].username == "anna"
      assert table.players[2].username == "bobo"
    end

    test "第三个玩家无法加入已满牌桌" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      {:ok, table} = PvpTable.join_table(table, "bobo", 500)
      assert {:error, :table_full} == PvpTable.join_table(table, "cindy", 500)
    end
  end

  describe "players_info/1" do
    test "返回玩家信息" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      {:ok, table} = PvpTable.join_table(table, "bobo", 500)

      assert [
               %{pos: 1, username: "anna", chips: 500, status: :JOINED},
               %{pos: 2, username: "bobo", chips: 500, status: :JOINED}
             ] ==
               PvpTable.players_info(table) |> Enum.sort_by(& &1.pos)
    end
  end

  describe "leave_table/2" do
    test "第一个玩家加入牌桌并离开" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      assert PvpTable.player_joined?(table, "anna") == true, "before leave table"
      assert {:ok, 500, _table} = PvpTable.leave_table(table, "anna")
    end

    test "玩家离开之后可以别人再加入" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      {:ok, table} = PvpTable.join_table(table, "bobo", 500)
      {:ok, _, table} = PvpTable.leave_table(table, "anna")
      assert {:ok, _table} = PvpTable.join_table(table, "cindy", 500)
    end
  end

  describe "start_game/2" do
    test "玩家加入桌子并开始游戏" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      assert {:ok, table} = PvpTable.start_game(table, "anna")
      assert table.players[1].status == :READY
    end
  end

  describe "can_table_start_game?/1" do
    test "只有一人开始不能开始游戏" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      {:ok, table} = PvpTable.start_game(table, "anna")
      assert PvpTable.can_table_start_game?(table) == false
    end

    test "固定两人开始情况下可以开始游戏" do
      table = PvpTable.new(2)
      {:ok, table} = PvpTable.join_table(table, "anna", 500)
      {:ok, table} = PvpTable.start_game(table, "anna")
      {:ok, table} = PvpTable.join_table(table, "bobo", 500)
      assert PvpTable.can_table_start_game?(table) == false
      {:ok, table} = PvpTable.start_game(table, "bobo")
      assert PvpTable.can_table_start_game?(table) == true
    end
  end
end
