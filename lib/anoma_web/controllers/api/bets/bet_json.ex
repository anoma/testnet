defmodule AnomaWeb.Api.BetJSON do
  @doc """
  Render a list of bets.
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

  @doc """
  Render a bet
  """
  def bet(bet) do
    bet
  end
end
