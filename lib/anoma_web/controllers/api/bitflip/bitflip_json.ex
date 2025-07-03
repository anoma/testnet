defmodule AnomaWeb.Api.BitflipJSON do
  @doc """
  Render a price.
  """
  def price(%{price: price}) do
    price
  end

  @doc """
  Render a list of bitflip.
  """
  def bets(%{bets: bets}) do
    %{bets: for(bet <- bets, do: bet(bet))}
  end

  @doc """
  Render the placed bet
  """
  def place(%{bet: bet}) do
    bet
  end

  @doc """
  Render a bet
  """
  def bet(%{bet: bet}) do
    bet
  end

  def bet(bet) do
    bet
  end
end
