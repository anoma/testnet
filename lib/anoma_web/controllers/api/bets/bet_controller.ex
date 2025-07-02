defmodule AnomaWeb.Api.BetController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Bets
  alias AnomaWeb.Api
  alias AnomaWeb.Api.BetController.Schemas

  use OpenApiSpex.ControllerSpecs

  action_fallback AnomaWeb.FallbackController

  # ----------------------------------------------------------------------------
  # OpenAPI Spec

  tags ["Bets"]

  operation :place,
    security: [%{"authorization" => []}],
    summary: "Place a bet",
    request_body: {"Bet Request", "application/json", Schemas.BetRequest},
    responses: %{
      200 => {"Bet", "application/json", Anoma.Pricing.Bet},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  @doc """
  Lets a user place a bet.
  """
  @spec place(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def place(conn, %{"up?" => up?, "leverage" => mutliplier, "points" => points}) do
    user = conn.assigns.current_user

    with {:ok, bet} <- Bets.place_bet(user, up?, mutliplier, points) do
      render(conn, :place, bet: bet)
    end
  end
end
