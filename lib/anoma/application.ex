defmodule Anoma.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Anoma.Accounts.DailyPoint
  alias Anoma.Accounts.User

  @impl true
  def start(_type, _args) do
    prod_children = [
      Anoma.PromEx,
      Anoma.Scheduler,
      Anoma.Coinbase
    ]

    dev_children = [
      Anoma.Scheduler
      # Anoma.Coinbase
    ]

    default_children = [
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
    ]

    children =
      case Mix.env() do
        :dev ->
          default_children ++ dev_children

        :prod ->
          default_children ++ prod_children

        _ ->
          default_children
      end

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
