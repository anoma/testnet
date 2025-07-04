defmodule AnomaWeb.Api.FitcoinController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Fitcoin
  alias AnomaWeb.Api
  alias AnomaWeb.Api.FitcoinController.Schemas

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  plug AnomaWeb.Plugs.RateLimit, action: :add
  # ----------------------------------------------------------------------------
  # OpenAPI Spec

  tags ["Fitcoins"]

  operation :add,
    security: [%{"authorization" => []}],
    summary: "Add fitcoin to the account of the user",
    responses: %{
      400 => {"Generic error", "application/json", Api.Schemas.Error},
      200 => {"Fitcoin balance", "application/json", Schemas.FitcoinBalance}
    }

  operation :balance,
    security: [%{"authorization" => []}],
    summary: "Returns the current fitcoin balance",
    responses: %{
      200 => {"Fitcoin balance", "application/json", Schemas.FitcoinBalance},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  # ----------------------------------------------------------------------------
  # Actions

  @doc """
  Adds 1 fitcoin to the user's account.
  """
  @spec add(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add(conn, %{}) do
    user = conn.assigns.current_user
    {:ok, user} = Fitcoin.add_fitcoin(user)

    render(conn, :balance, fitcoins: user.fitcoins)
  end

  def balance(conn, %{}) do
    user = conn.assigns.current_user
    {:ok, balance} = Fitcoin.balance(user)

    render(conn, :balance, fitcoins: balance)
  end
end
