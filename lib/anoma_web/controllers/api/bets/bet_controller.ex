defmodule AnomaWeb.Api.BetController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Bets
  alias Anoma.Pricing.Bet
  alias Anoma.Accounts
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

  # ----------------------------------------------------------------------------
  # Actions

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

  @doc """
  Lets a user place a bet.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"bet_id" => bet_id}) do
      conn.assigns.current_user
      |> Anoma.Repo.preload(:bets)
      |> Enum.find(&(&1.id == bet_id))
      |> case do
        %Bet{} = bet ->
          render(conn, :bet, bet: bet)

        _ ->
          {:error, :bet_not_found}
      end
  end
end
