defmodule ExPoker.Core.PvpRulesEngineTest do
  use ExUnit.Case

  alias ExPoker.Core.PvpRulesEngine

  describe "new/3" do
    test "成功创建rules engine" do
      assert %PvpRulesEngine.State{
               street: :preflop,
               button: "anna",
               players_order: ["anna", "bob"]
             } =
               PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{
                 "anna" => 5,
                 "bob" => 10
               })
    end

    test "成功完成初始盲注下注" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.pot == 0
      assert state.players["anna"].chips_left == 995
      assert state.players["bob"].chips_left == 490
    end

    test "preflop阶段从小盲(button)开始行动" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.next_player == "anna"
      assert state.first_player == nil
    end

    test "验证第一个行动状态正确设定" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.next_action == {:player, {"anna", [:fold, {:call, 5}, :raise]}}
    end
  end

  describe "handle_player_action/3处理第一行动玩家" do
    test "首个行动玩家call正确更新下注信息" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.pot == 0
      assert state.players["anna"].chips_left == 995
      assert state.players["anna"].current_street_bet == 5

      state2 = PvpRulesEngine.handle_player_action(state, "anna", :call)

      assert state2.pot == 0
      assert state2.players["anna"].chips_left == 990
      assert state2.players["anna"].current_street_bet == 10
    end

    test "首个行动玩家call正确更新first_player玩家信息" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.first_player == nil
      state2 = PvpRulesEngine.handle_player_action(state, "anna", :call)
      assert state2.first_player == "anna"
    end

    test "第一玩家直接raise最终还是回到该玩家" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.first_player == nil
      state2 = PvpRulesEngine.handle_player_action(state, "anna", {:raise, 20})
      assert state2.first_player == "anna"
    end

    test "玩家call之后正确前进到下一个玩家" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.next_player == "anna"
      state2 = PvpRulesEngine.handle_player_action(state, "anna", :call)
      assert state2.next_player == "bob"
    end

    test "玩家raise之后改变当前需要call的amount" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      state2 = PvpRulesEngine.handle_player_action(state, "anna", {:raise, 20})
      assert state2.current_call_amount == 5 + 20
    end
  end

  describe "handle_player_action/3处理第二玩家行动" do
    test "第一玩家call之后轮到第二玩家行动" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      assert state.next_action == {:player, {"anna", [:fold, {:call, 5}, :raise]}}
      state2 = PvpRulesEngine.handle_player_action(state, "anna", :call)
      assert state2.next_action == {:player, {"bob", [:fold, :check, :raise]}}
    end

    test "玩家check不改变first_player位置" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})

      state = PvpRulesEngine.handle_player_action(state, "anna", :call)
      assert state.first_player == "anna"
      # 后位玩家check不会再回到前位玩家行动
      state = PvpRulesEngine.handle_player_action(state, "bob", :check)
      assert state.first_player == "anna"
    end

    test "第二玩家也完成行动之后, 本轮下注结束, 将玩家当前下注移入pot" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", :check)

      assert state.pot == 20
      assert state.players["anna"].current_street_bet == 0
      assert state.players["bob"].current_street_bet == 0
    end

    test "第二玩家再raise改变最终玩家位置" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", {:raise, 20})

      assert state.first_player == "bob"
    end
  end

  describe "handle_table_action/3处理牌桌发牌事件" do
    test "第二玩家也完成行动之后, 本轮下注结束, 接下来该发牌操作" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", :check)

      assert state.next_action == {:table, {:deal, :flop}}
    end

    test "发牌flop之后, 更新street" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", :check)
        |> PvpRulesEngine.handle_table_action({:done, :flop})

      assert state.street == :flop
    end

    test "发牌flop之后, 轮到非button玩家行动" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", :check)
        |> PvpRulesEngine.handle_table_action({:done, :flop})

      assert state.next_player == "bob"
    end

    test "发牌flop之后, 下注信息正确设置" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", :check)
        |> PvpRulesEngine.handle_table_action({:done, :flop})

      assert state.pot == 20
      assert state.current_call_amount == 0
      assert state.players["anna"].current_street_bet == 0
      assert state.players["bob"].current_street_bet == 0
    end

    test "发牌flop之后, next_action设置正确" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :call)
        |> PvpRulesEngine.handle_player_action("bob", :check)
        |> PvpRulesEngine.handle_table_action({:done, :flop})

      assert state.next_action == {:player, {"bob", [:fold, :check, :raise]}}
    end
  end

  describe "next_action验证" do
    test "一方fold则另一方自动获胜" do
      state =
        PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
        |> PvpRulesEngine.handle_player_action("anna", :fold)

      assert state.next_action == {:winner, "bob", %{"anna" => 995, "bob" => 505}}
    end

    test "最简单双方一路check到河牌摊牌" do
      PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
      # preflop
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, {:call, 5}, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :call)
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:table, {:deal, :flop}} end)
      |> PvpRulesEngine.handle_table_action({:done, :flop})
      # 进入flop阶段
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :check)
      |> tap(fn s -> assert s.next_action == {:table, {:deal, :turn}} end)
      |> PvpRulesEngine.handle_table_action({:done, :turn})
      # 进入turn阶段
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :check)
      |> tap(fn s -> assert s.next_action == {:table, {:deal, :river}} end)
      |> PvpRulesEngine.handle_table_action({:done, :river})
      # 进入river阶段
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :check)
      |> tap(fn s ->
        assert s.next_action == {:table, {:show_hands, 20, %{"anna" => 990, "bob" => 490}}}
      end)
    end

    test "河牌阶段的下注会正确进入最终结果" do
      PvpRulesEngine.new([{"anna", 1000}, {"bob", 500}], "anna", %{"anna" => 5, "bob" => 10})
      # preflop
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, {:call, 5}, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :call)
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:table, {:deal, :flop}} end)
      |> PvpRulesEngine.handle_table_action({:done, :flop})
      # 进入flop阶段
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :check)
      |> tap(fn s -> assert s.next_action == {:table, {:deal, :turn}} end)
      |> PvpRulesEngine.handle_table_action({:done, :turn})
      # 进入turn阶段
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :check)
      |> tap(fn s -> assert s.next_action == {:player, {"anna", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("anna", :check)
      |> tap(fn s -> assert s.next_action == {:table, {:deal, :river}} end)
      |> PvpRulesEngine.handle_table_action({:done, :river})
      # 进入river阶段
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, :check, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", {:raise, 100})
      |> tap(fn s ->
        assert s.next_action == {:player, {"anna", [:fold, {:call, 100}, :raise]}}
      end)
      |> PvpRulesEngine.handle_player_action("anna", {:raise, 280})
      |> tap(fn s -> assert s.next_action == {:player, {"bob", [:fold, {:call, 180}, :raise]}} end)
      |> PvpRulesEngine.handle_player_action("bob", :call)
      |> tap(fn s ->
        assert s.next_action ==
                 {:table,
                  {:show_hands, 20 + 280 * 2,
                   %{"anna" => 1000 - 10 - 280, "bob" => 500 - 10 - 280}}}
      end)
    end
  end
end
