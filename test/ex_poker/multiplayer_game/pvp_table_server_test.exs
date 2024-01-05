defmodule ExPoker.MultiplayerGame.PvpTableServerTest do
  use ExUnit.Case

  alias ExPoker.MultiplayerGame.Table
  alias ExPoker.MultiplayerGame.PvpTableServer

  @table_cfg %{name: "test", sb: 1, bb: 2, max_players: 2, buyin: 500}

  describe "start_link/1" do
    test "start a new table server" do
      assert {:ok, _pid} = start_supervised({PvpTableServer, @table_cfg})
    end
  end

  describe "join_table" do
    test "第一个玩家加入桌子" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      assert :ok == Table.join_table(pid, "anna")
    end

    test "两个玩家成功加入桌子" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      assert :ok == Table.join_table(pid, "bobo")
    end

    test "第三个玩家无法加入" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      :ok = Table.join_table(pid, "bobo")
      assert {:error, _} = Table.join_table(pid, "emma")
    end
  end

  describe "leave_table" do
    test "第一个玩家加入桌子" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      assert {:ok, 500} == Table.leave_table(pid, "anna")
    end
  end

  describe "start_game" do
    test "玩家加入桌子并启动游戏" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      assert :ok == Table.start_game(pid, "anna")
    end
  end

  describe "玩家加入离开桌子过程通知所有玩家" do
    test "第一个玩家加入, 自己收到玩家信息" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")

      assert_receive {:"$gen_cast",
                      {:players_info, [%{status: :JOINED, pos: 1, username: "anna", chips: 500}]}}
    end

    test "唯一玩家离开桌子可以正常工作" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      flush(1)
      {:ok, _} = Table.leave_table(pid, "anna")
      :ok = Table.join_table(pid, "bobo")

      assert_receive {:"$gen_cast",
                      {:players_info, [%{status: :JOINED, pos: 1, username: "bobo", chips: 500}]}}
    end

    test "第二个玩家加入, 两个玩家都收到玩家信息" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")

      receive do
        {:"$gen_cast", {:players_info, [_]}} ->
          :ok
      end

      :ok = Table.join_table(pid, "bobo")
      # Broadcast to both players
      assert_receive {:"$gen_cast", {:players_info, [_, _]}}
      assert_receive {:"$gen_cast", {:players_info, [_, _]}}
    end

    test "玩家离开的时候能够得到通知" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      flush(1)
      :ok = Table.join_table(pid, "bobo")
      flush(2)
      Table.leave_table(pid, "anna")

      assert_receive {:"$gen_cast",
                      {:players_info, [%{status: :JOINED, pos: 2, username: "bobo", chips: 500}]}}
    end
  end

  describe "玩家状态变化(开始游戏)通知所有玩家" do
    test "玩家开始游戏通知所有玩家" do
      {:ok, pid} = start_supervised({PvpTableServer, @table_cfg})
      :ok = Table.join_table(pid, "anna")
      assert_receive {:"$gen_cast", {:players_info, [%{status: :JOINED}]}}
      assert :ok == Table.start_game(pid, "anna")
      assert_receive {:"$gen_cast", {:players_info, [%{status: :WAITING}]}}
    end
  end

  defp flush(n) do
    1..n
    |> Enum.each(fn _ ->
      receive do
        _ -> :ok
      end
    end)
  end
end
