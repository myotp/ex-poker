defmodule ExPoker.MultiplayerGame.TableConfig do
  @type t :: %__MODULE__{
          name: String.t(),
          pid: pid(),
          max_players: pos_integer(),
          sb: pos_integer(),
          bb: pos_integer(),
          buyin: pos_integer()
        }

  defstruct [
    :name,
    :pid,
    :max_players,
    :sb,
    :bb,
    :buyin
  ]

  @spec new!(keyword() | map()) :: ExPoker.MultiplayerGame.TableConfig.t()
  def new!(params) do
    %__MODULE__{
      name: Access.get(params, :name) || random_table_name(),
      pid: self(),
      max_players: Access.fetch!(params, :max_players),
      sb: Access.fetch!(params, :sb),
      bb: Access.fetch!(params, :bb),
      buyin: Access.fetch!(params, :buyin)
    }
  end

  defp random_table_name() do
    Enum.random(["aaa", "bbb", "ccc"])
  end
end
