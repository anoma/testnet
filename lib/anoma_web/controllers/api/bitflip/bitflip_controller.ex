defmodule AnomaWeb.Api.BitflipController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Assets
  alias Anoma.Bitflip
  alias Anoma.Bitflip.Bet
  alias AnomaWeb.Api
  alias AnomaWeb.Api.BitflipController.Schemas

  use OpenApiSpex.ControllerSpecs

  action_fallback AnomaWeb.FallbackController

  # ----------------------------------------------------------------------------
  # OpenAPI Spec

  tags ["Bitflip"]

  operation :place,
    security: [%{"authorization" => []}],
    summary: "Place a bet",
    request_body: {"Bet Request", "application/json", Schemas.BetRequest},
    responses: %{
      200 => {"Bet", "application/json", Anoma.Bitflip.Bet},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :get,
    security: [%{"authorization" => []}],
    summary: "Get the information about a bet",
    parameters: [
      id: [in: :path, schema: Schemas.BetDetailsRequest]
    ],
    responses: %{
      200 => {"Bet", "application/json", Anoma.Bitflip.Bet},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :list,
    security: [%{"authorization" => []}],
    summary: "Get all the user's bets",
    responses: %{
      200 => {"Bitflip", "application/json", Schemas.BetList},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :price,
    security: [%{"authorization" => []}],
    summary: "Get the latest known price.",
    responses: %{
      200 => {"Bitflip", "application/json", Anoma.Assets.Currency},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  # ----------------------------------------------------------------------------
  # Actions

  @doc """
  Returns the latest price of bitcoin.
  """
  @spec price(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def price(conn, _params) do
    Assets.last_price("BTC-USD")
    render(conn, :price, price: Assets.last_price("BTC-USD"))
  end

  @doc """
  Lets a user place a bet.
  """
  @spec place(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def place(conn, %{"up" => up?, "leverage" => mutliplier, "points" => points}) do
    user = conn.assigns.current_user

    with {:ok, bet} <- Bitflip.place_bet(user, up?, mutliplier, points) do
      render(conn, :place, bet: bet)
    end
  end

  @doc """
  Lets a user place a bet.
  """
  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"id" => bet_id}) do
    conn.assigns.current_user
    |> Anoma.Repo.preload(:bets)
    |> Map.get(:bets)
    |> Enum.find(&(&1.id == bet_id))
    |> case do
      %Bet{} = bet ->
        render(conn, :bet, bet: bet)

      _ ->
        {:error, :bet_not_found}
    end
  end

  @doc """
  Lets a user place a bet.
  """
  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, _params) do
    user =
      conn.assigns.current_user
      |> Anoma.Repo.preload(:bets)

    render(conn, :bets, bets: user.bets)
  end
end
