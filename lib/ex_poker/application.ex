defmodule ExPoker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExPokerWeb.Telemetry,
      ExPoker.Repo,
      {DNSCluster, query: Application.get_env(:ex_poker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ExPoker.PubSub},
      # Start a worker by calling: ExPoker.Worker.start_link(arg)
      # {ExPoker.Worker, arg},
      # Start to serve requests, typically the last entry
      ExPokerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExPoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExPokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
