defmodule AlchemicalLife.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AlchemicalLifeWeb.Telemetry,
      AlchemicalLife.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:alchemical_life, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:alchemical_life, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AlchemicalLife.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AlchemicalLife.Finch},
      # Start a worker by calling: AlchemicalLife.Worker.start_link(arg)
      # {AlchemicalLife.Worker, arg},
      # Start to serve requests, typically the last entry
      AlchemicalLifeWeb.Endpoint,
      # Start the Game of Life GenServer
      {AlchemicalLife.Life.Game, grid: AlchemicalLife.Life.Game.default_grid()}

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlchemicalLife.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlchemicalLifeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
