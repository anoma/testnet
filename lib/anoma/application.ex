defmodule Anoma.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Anoma.Accounts.User
  alias Anoma.DailyPoints.DailyPoint

  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Application commit: #{Application.get_env(:anoma, :git_commit_sha)}")

    children =
      if Application.get_env(:anoma, :promex) do
        [Anoma.PromEx]
      else
        []
      end ++
        [
          Anoma.RateLimit,
          AnomaWeb.Telemetry,
          Anoma.Repo,
          {DNSCluster, query: Application.get_env(:anoma, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: Anoma.PubSub},
          # Start a worker by calling: Anoma.Worker.start_link(arg)
          # {Anoma.Worker, arg},
          # Start to serve requests, typically the last entry
          AnomaWeb.Endpoint,
          {EctoWatch,
           repo: Anoma.Repo,
           pub_sub: Anoma.PubSub,
           watchers: [
             {DailyPoint, :inserted},
             {User, :updated}
           ]}
        ] ++
        Application.get_env(:anoma, :children)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Anoma.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnomaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
