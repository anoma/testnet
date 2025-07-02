defmodule AnomaWeb.Api.CouponController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Accounts.Coupons
  alias AnomaWeb.Api
  alias AnomaWeb.Api.CouponController.Schemas

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs
  tags ["Daily Coupons"]

  operation :list,
    security: [%{"authorization" => []}],
    summary: "List of available coupons",
    responses: %{
      200 => {"List of Coupons", "application/json", Schemas.CouponList},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :use,
    security: [%{"authorization" => []}],
    summary: "Redeem a coupon",
    request_body: {"Coupon Redeem Request", "application/json", Schemas.RedeemRequest},
    responses: %{
      400 => {"Generic error", "application/json", Api.Schemas.Error},
      200 => {"Failure", "application/json", Api.Schemas.Success}
    }

  @doc """
  Returns the list of coupons.
  """
  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, %{}) do
    user = conn.assigns.current_user
    coupons = Coupons.list_coupons(user)

    render(conn, :coupons, coupons: coupons)
  end

  @doc """
  Consumes a coupon
  """
  @spec use(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def use(conn, %{"id" => coupon_id}) do
    user = conn.assigns.current_user

    # make sure the coupon is owned by this user.
    coupon = Coupons.get_coupon!(coupon_id)

    # if this coupon is not owned by this user, can't consume it.
    if coupon.owner_id == user.id do
      {:ok, coupon} = Coupons.use_coupon(coupon)

      render(conn, :use, coupon: coupon)
    else
      {:error, :invalid_coupon}
    end
  end
end
