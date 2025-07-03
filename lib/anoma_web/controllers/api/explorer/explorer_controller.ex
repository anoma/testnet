defmodule AnomaWeb.Api.ExplorerController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Fitcoin
  alias AnomaWeb.Api
  alias AnomaWeb.Api.ExplorerController.Schemas
  alias Anoma.DailyPoints

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  plug AnomaWeb.Plugs.RateLimit, action: :add
  # ----------------------------------------------------------------------------
  # OpenAPI Spec

  tags ["Daily Rewards"]

  operation :list,
    security: [%{"authorization" => []}],
    summary: "List current daily rewards",
    responses: %{
      400 => {"Generic error", "application/json", Api.Schemas.Error},
      200 => {"Fitcoin balance", "application/json", Schemas.DailyPointsList}
    }

  # ----------------------------------------------------------------------------
  # Actions

  @doc """
  List the current daily rewards.
  """
  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, %{}) do
    user = conn.assigns.current_user
    daily_points = DailyPoints.get_user_daily_points(user)

    render(conn, :list, daily_points: daily_points)
  end
end
