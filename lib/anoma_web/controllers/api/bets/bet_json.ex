defmodule AnomaWeb.Api.BetJSON do
  @doc """
  Render the placed bet
  """
  def place(%{bet: bet}) do
    %{bet: bet}
  end
end
