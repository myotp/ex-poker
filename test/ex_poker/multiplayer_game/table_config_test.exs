defmodule ExPoker.MultiplayerGame.TableConfigTest do
  use ExUnit.Case
  alias ExPoker.MultiplayerGame.TableConfig

  describe "new!/1" do
    test "参数map成功创建TableConfig" do
      assert table_info =
               %TableConfig{
                 name: "test",
                 max_players: 6,
                 sb: 1,
                 bb: 2,
                 buyin: 500
               } =
               TableConfig.new!(%{name: "test", sb: 1, bb: 2, buyin: 500, max_players: 6})

      assert is_pid(table_info.pid)
    end

    test "name如果缺失则生成随机名字" do
      table_info = TableConfig.new!(%{sb: 1, bb: 2, max_players: 6, buyin: 500})
      assert table_info.name != nil
    end
  end
end
