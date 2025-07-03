defmodule AnomaWeb.Api.ExplorerJSON do
  @doc """
  Render the garapon coupons.
  """
  def list(%{daily_points: daily_points}) do
    %{daily_points: for(daily_point <- daily_points, do: daily_point(daily_point))}
  end

  def daily_point(%{daily_point: daily_point}) do
    daily_point
  end

  def daily_point(daily_point) do
    daily_point
  end
end
