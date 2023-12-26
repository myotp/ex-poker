defmodule ExPoker.Repo do
  use Ecto.Repo,
    otp_app: :ex_poker,
    adapter: Ecto.Adapters.Postgres
end
