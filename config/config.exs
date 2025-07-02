# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :anoma,
  ecto_repos: [Anoma.Repo],
  generators: [timestamp_type: :utc_datetime],
  children: [Anoma.Scheduler, Anoma.Coinbase],
  debug_auth: false,
  promex: true

# Configures the endpoint
config :anoma, AnomaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: AnomaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Anoma.PubSub,
  live_view: [signing_salt: "auDUoaM2"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :anoma, Anoma.Scheduler,
  jobs: [
    # {"@daily", {Backup, :backup, []}}
  ]

config :anoma, Anoma.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
