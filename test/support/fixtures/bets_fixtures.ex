defmodule Anoma.BetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Anoma.Pricing` context.
  """

  @doc """
  Generate a bet.
  """
  def bet_fixture(attrs \\ %{}) do
    {:ok, bet} =
      attrs
      |> Enum.into(%{
        multiplier: 42,
        points: 42,
        up: true
      })
      |> Anoma.Bets.create_bet()

    bet
  end
end
