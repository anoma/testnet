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
  promex: true,
  git_commit_sha: System.get_env("GIT_COMMIT_SHA", "no-commit-info")

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
    # Every minute
    {{:extended, "* * * * *"}, {Anoma.Tasks, :settle_bets, []}},
    # # Every 15 minutes
    # {"*/15 * * * *",   fn -> System.cmd("rm", ["/tmp/tmp_"]) end},
    # # Runs on 18, 20, 22, 0, 2, 4, 6:
    # {"0 18-6/2 * * *", fn -> :mnesia.backup('/var/backup/mnesia') end},
    # Runs every midnight:
    {"@daily", {Anoma.Tasks, :create_daily_coupons, []}}
  ]

config :anoma, Anoma.PromEx,
  disabled: false,
  manual_metrics_start_delay: 500_000,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
