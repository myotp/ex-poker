defmodule ExPoker.Core.HandHistory do
  @type player_action :: {:user, String.t(), :check | :fold | {:call, pos_integer()}}
  @type table_action :: {:deal, :flop | :turn | :river, String.t()}

  @type t :: %__MODULE__{
          game_id: pos_integer() | nil,
          start_time: NaiveDateTime.t(),
          sb_amount: pos_integer(),
          bb_amount: pos_integer(),
          blinds: [{String.t(), pos_integer()}],
          players: [%{pos: pos_integer(), username: String.t(), chips: pos_integer()}],
          button_pos: pos_integer(),
          hole_cards: %{optional(String.t()) => String.t()},
          community_cards: String.t(),
          actions: [table_action() | player_action()],
          #
          format: String.t(),
          table_name: String.t(),
          poker_type: String.t(),
          table_type: String.t()
        }
  defstruct [
    # 牌桌游戏对局的基本信息, 一些固定硬编码的在最后
    :game_id,
    :start_time,

    # 大小盲及盲注下注信息, 多人底池谁下多少盲由rules给出指引
    :sb_amount,
    :bb_amount,
    :blinds,
    :button_pos,

    # 玩家信息, 座位号, 用户名, 筹码数量
    :players,

    # 动态牌信息
    community_cards: "",
    hole_cards: %{},

    # 一系列发牌玩家操作事件列表
    actions: [],

    # hard coded attrs
    format: "PokerStars",
    table_name: "Vala",
    poker_type: "Hold'em No Limit",
    table_type: "6-max"
  ]

  @spec new(
          [%{pos: pos_integer(), username: String.t(), chips: pos_integer()}],
          pos_integer(),
          {pos_integer(), pos_integer()},
          [{String.t(), pos_integer()}]
        ) :: ExPoker.Core.HandHistory.t()
  def new(players, button_pos, {sb, bb}, blinds) do
    %__MODULE__{
      start_time: NaiveDateTime.utc_now(:second),
      players: players,
      button_pos: button_pos,
      sb_amount: sb,
      bb_amount: bb,
      blinds: blinds
    }
  end

  @spec example() :: ExPoker.Core.HandHistory.t()
  def example() do
    %__MODULE__{
      game_id: 246_256_820_433,
      start_time: NaiveDateTime.utc_now(:second),
      players: [
        %{pos: 3, username: "Lucas", chips: 15},
        %{pos: 5, username: "Anna", chips: 20}
      ],
      button_pos: 5,
      sb_amount: 1,
      bb_amount: 2,
      blinds: [{"Anna", 1}, {"Lucas", 2}],
      hole_cards: [{"Lucas", "Ah Qc"}, {"Anna", "3d 2d"}],
      community_cards: "Qh 7h 5d 8c 9s",
      actions: [
        {:player, "Anna", {:call, 1}},
        {:player, "Lucas", :check},
        {:deal, :flop, "Qh 7h 5d"},
        {:player, "Lucas", :check},
        {:player, "Anna", :check},
        {:deal, :turn, "Qh 7h 5d 8c"},
        {:player, "Lucas", :check},
        {:player, "Anna", :check},
        {:deal, :river, "Qh 7h 5d 8c 9s"},
        {:player, "Lucas", :check},
        {:player, "Anna", :check}
      ]
    }
  end
end
