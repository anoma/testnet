defmodule Anoma.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias Anoma.Repo

  alias Anoma.Assets.Currency

  @doc """
  Returns the list of currencies.

  ## Examples

      iex> list_currencies()
      [%Currency{}, ...]

  """
  def list_currencies do
    Repo.all(Currency)
  end

  @doc """
  Gets a single currency.

  Raises `Ecto.NoResultsError` if the Currency does not exist.

  ## Examples

      iex> get_currency!(123)
      %Currency{}

      iex> get_currency!(456)
      ** (Ecto.NoResultsError)

  """
  def get_currency!(id), do: Repo.get!(Currency, id)

  @doc """
  Creates a currency.

  ## Examples

      iex> create_currency(%{field: value})
      {:ok, %Currency{}}

      iex> create_currency(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_currency(attrs \\ %{}) do
    %Currency{}
    |> Currency.changeset(attrs)
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:currency, :timestamp]
    )
  end

  @doc """
  Given a timestamp, I return the value of the given currency stricly after the given timestamp.
  E.g., asking for the currency at 12:01 will return the newest value, since the timestamp, or nil if there arent any.
  """
  def price_at(currency, timestamp) do
    # the price can be 5 seconds older than right now
    start_window = DateTime.add(timestamp, -5, :second)
    end_window = DateTime.add(timestamp, 5, :second)

    from(c in Currency,
      where: c.currency == ^currency,
      where: c.timestamp >= ^start_window,
      where: c.timestamp <= ^end_window,
      order_by: {:desc, c.timestamp},
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Returns the latest price for the given currency.
  """
  def last_price(currency) do
    from(c in Currency,
      where: c.currency == ^currency,
      order_by: {:desc, c.timestamp},
      limit: 1
    )
    |> Repo.one()
  end
end
