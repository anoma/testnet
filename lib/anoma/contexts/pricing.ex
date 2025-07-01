defmodule Anoma.Pricing do
  @moduledoc """
  The Pricing context.
  """

  import Ecto.Query, warn: false
  alias Anoma.Repo

  alias Anoma.Pricing.Currency

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
    |> Repo.insert()
  end

  @doc """
  Given a timestamp, I return the value of the given currency stricly after the given timestamp.
  E.g., asking for the currency at 12:01 will return the newest value, since the timestamp, or nil if there arent any.
  """
  def price_at(currency, timestamp) do
    from(c in Currency,
      where: c.currency == ^currency,
      where: c.inserted_at >= ^timestamp,
      order_by: {:asc, c.inserted_at},
      limit: 1
    )
    |> Repo.one()
  end
end
