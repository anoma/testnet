defmodule AnomaWeb.Api.CouponController.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule RedeemRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Coupon redeem request",
      type: :object,
      properties: %{
        id: %Schema{
          type: :integer,
          description: "Coupon ID",
          example: "18d3bb76-2e27-4cd0-9912-b8b259bd3950"
        }
      }
    })
  end

  defmodule BuyRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Coupon purchase request",
      type: :object,
      properties: %{
        amount: %Schema{
          type: :integer,
          description: "Amount of coupons to buy",
          example: "1000"
        }
      }
    })
  end

  defmodule CouponList do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{coupons: %Schema{type: :array, items: Anoma.Garapon.Coupon}}
    })
  end
end
