defmodule AnomaWeb.Api.FitcoinController.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule RedeemRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Bet Request",
      type: :object,
      properties: %{id: %Schema{type: :integer, description: "Coupon ID"}}
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

  defmodule FitcoinBalance do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{fitcoins: %Schema{type: :integer}}
    })
  end
end
