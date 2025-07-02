defmodule AnomaWeb.Api.FitcoinController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Accounts
  alias AnomaWeb.Api.FitcoinController.Schemas
  alias AnomaWeb.Api

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  tags ["Fitcoins"]

  operation :add,
    security: [%{"authorization" => []}],
    summary: "Add fitcoin to the account of the user",
    responses: %{
      200 => {"Fitcoin added", "application/json", Api.Schemas.Success},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :balance,
    security: [%{"authorization" => []}],
    summary: "Returns the current fitcoin balance",
    responses: %{
      200 => {"Fitcoin balance", "application/json", Schemas.FitcoinBalance},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  @doc """
  Adds 1 fitcoin to the user's account.
  """
  @spec add(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add(conn, %{}) do
    user = conn.assigns.current_user
    {:ok, user} = Accounts.Fitcoin.add_fitcoin(user)

    render(conn, :balance, fitcoins: user.fitcoins)
  end

  def balance(conn, %{}) do
    user = conn.assigns.current_user
    {:ok, balance} = Accounts.Fitcoin.balance(user)

    render(conn, :balance, fitcoins: balance)
  end
end
