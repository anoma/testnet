defmodule AnomaWeb.Api.CouponController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Garapon
  alias AnomaWeb.Api
  alias AnomaWeb.Api.CouponController.Schemas

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  # ----------------------------------------------------------------------------
  # OpenAPI Spec

  tags ["Garapon"]

  operation :list,
    security: [%{"authorization" => []}],
    summary: "List of available coupons",
    responses: %{
      200 => {"List of Garapon", "application/json", Schemas.CouponList},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :use,
    security: [%{"authorization" => []}],
    summary: "Redeem a coupon",
    request_body: {"Coupon Redeem Request", "application/json", Schemas.RedeemRequest},
    responses: %{
      400 => {"Generic error", "application/json", Api.Schemas.Error},
      200 => {"Success", "application/json", Garapon.Coupon}
    }

  operation :buy,
    security: [%{"authorization" => []}],
    summary: "Buy a coupon with fitcoins",
    responses: %{
      400 => {"Generic error", "application/json", Api.Schemas.Error},
      200 => {"Success", "application/json", Garapon.Coupon}
    }

  # ----------------------------------------------------------------------------
  # Actions

  @doc """
  Returns the list of coupons.
  """
  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, %{}) do
    user = conn.assigns.current_user
    coupons = Garapon.list_coupons(user)

    render(conn, :coupons, coupons: coupons)
  end

  @doc """
  Consumes a coupon
  """
  @spec use(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def use(conn, %{"id" => coupon_id}) do
    user = conn.assigns.current_user

    # make sure the coupon is owned by this user.
    coupon = Garapon.get_coupon!(coupon_id)

    # if this coupon is not owned by this user, can't consume it.
    if coupon.owner_id == user.id do
      {:ok, coupon} = Garapon.use_coupon(coupon)

      render(conn, :use, coupon: coupon)
    else
      {:error, :invalid_coupon}
    end
  end

  @spec buy(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def buy(conn, _params) do
    user = conn.assigns.current_user

    with {:ok, coupon} <- Garapon.buy_coupon(user) do
      render(conn, :coupon, coupon: coupon)
    end
  end
end
