defmodule AnomaWeb.Api.CouponJSON do
  @doc """
  Render the garapon coupons.
  """
  def coupons(%{coupons: coupons}) do
    %{coupons: for(coupon <- coupons, do: coupon(coupon))}
  end

  @doc """
  Returns success upon using a coupon
  """
  def use(%{coupon: coupon}) do
    coupon
  end

  @doc """
  Renders a single coupon.
  """
  def coupon(coupon) do
    coupon
  end
end
