defmodule AnomaWeb.Api.FitcoinJSON do
  @doc """
  Render the fitcoin balance.
  """
  def balance(%{fitcoins: fitcoins}) do
    %{fitcoins: fitcoins}
  end
end
