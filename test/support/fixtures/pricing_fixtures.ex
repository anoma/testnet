defmodule Anoma.PricingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Anoma.Pricing` context.
  """

  @doc """
  Generate a currency.
  """
  def currency_fixture(attrs \\ %{}) do
    {:ok, currency} =
      attrs
      |> Enum.into(%{
        currency: "some currency",
        price: 120.5,
        timestamp: DateTime.utc_now()
      })
      |> Anoma.Pricing.create_currency()

    currency
  end
end
