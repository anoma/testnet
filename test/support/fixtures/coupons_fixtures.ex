defmodule Anoma.GaraponFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Anoma.Garapon` context.
  """
  alias Anoma.Garapon

  @doc """
  Generate a coupon.
  """
  def coupon_fixture(attrs \\ %{}) do
    {:ok, coupon} =
      attrs
      |> Enum.into(%{})
      |> Garapon.create_coupon()

    coupon
  end
end
