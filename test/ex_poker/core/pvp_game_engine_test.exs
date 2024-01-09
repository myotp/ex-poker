defmodule ExPoker.Core.PvpGameEngineTest do
  use ExUnit.Case

  alias ExPoker.Core.PvpGameEngine

  describe "new" do
    test "成功创建game_engine" do
      players = [
        %{pos: 1, username: "anna", chips: 500},
        %{pos: 2, username: "bobo", chips: 500}
      ]

      assert %PvpGameEngine{} = PvpGameEngine.new(players, 1, {1, 2})
    end

    test "正确设置大小盲并记录在hand_history当中" do
      players = [
        %{pos: 1, username: "anna", chips: 500},
        %{pos: 2, username: "bobo", chips: 500}
      ]

      game_engine = PvpGameEngine.new(players, 1, {10, 20})
      assert game_engine.hand_history.blinds == [{"anna", 10}, {"bobo", 20}]
    end

    test "创建game_engine之后下一步操作正确设置" do
      players = [
        %{pos: 1, username: "anna", chips: 500},
        %{pos: 2, username: "bobo", chips: 500}
      ]

      game_engine = PvpGameEngine.new(players, 1, {10, 20})

      assert PvpGameEngine.next_action(game_engine) ==
               {:player, {"anna", [:fold, {:call, 10}, :raise]}}
    end
  end

  describe "bets_info/1" do
    test "初始大小盲注返回" do
      players = [
        %{pos: 1, username: "anna", chips: 500},
        %{pos: 2, username: "bobo", chips: 500}
      ]

      game_engine = PvpGameEngine.new(players, 1, {1, 2})

      assert PvpGameEngine.bets_info(game_engine) == %{
               :pot => 3,
               "anna" => %{chips_left: 499, current_street_bet: 1},
               "bobo" => %{chips_left: 498, current_street_bet: 2}
             }
    end
  end
end
