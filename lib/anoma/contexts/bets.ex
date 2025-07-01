defmodule Anoma.Bets do
  @moduledoc """
  The Pricing context.
  """

  import Ecto.Query, warn: false

  alias Anoma.Accounts.DailyPoints
  alias Anoma.Invites
  alias Anoma.Pricing.Bet
  alias Anoma.Pricing.Currency
  alias Anoma.Repo

  require Logger

  @doc """
  Returns the list of bets.

  ## Examples

      iex> list_bets()
      [%Bet{}, ...]

  """
  def list_bets do
    Repo.all(Bet)
  end

  @doc """
  Gets a single bet.

  Raises `Ecto.NoResultsError` if the Bet does not exist.

  ## Examples

      iex> get_bet!(123)
      %Bet{}

      iex> get_bet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bet!(id), do: Repo.get!(Bet, id)

  @doc """
  Creates a bet.

  ## Examples

      iex> create_bet(%{field: value})
      {:ok, %Bet{}}

      iex> create_bet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bet(attrs \\ %{}) do
    %Bet{}
    |> Bet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bet.

  ## Examples

      iex> update_bet(bet, %{field: new_value})
      {:ok, %Bet{}}

      iex> update_bet(bet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bet(%Bet{} = bet, attrs) do
    bet
    |> Bet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bet.

  ## Examples

      iex> delete_bet(bet)
      {:ok, %Bet{}}

      iex> delete_bet(bet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bet(%Bet{} = bet) do
    Repo.delete(bet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bet changes.

  ## Examples

      iex> change_bet(bet)
      %Ecto.Changeset{data: %Bet{}}

  """
  def change_bet(%Bet{} = bet, attrs \\ %{}) do
    Bet.changeset(bet, attrs)
  end

  @doc """
  I settle a bet if its possible.
  """
  def settle_bet(%Bet{} = bet) do
    # fetch the user of the bet
    bet = Repo.preload(bet, :user)

    case can_settle?(bet) do
      {:ok, {price_at_bet, price_at_settle, settle_time}} ->
        # check if this bet was won or lost.
        won? =
          case {price_at_bet > price_at_settle, bet.up} do
            {true, true} ->
              true

            {false, false} ->
              true

            _ ->
              false
          end

        # compute the gas that this bet has cost.
        gas_cost = :math.pow(bet.multiplier, 2) * 10
        points_won = bet.points * bet.multiplier

        Logger.debug("""

        Bet made at     #{bet.inserted_at}
        Bet settle at   #{settle_time}
        Price at bet    #{price_at_bet}
        Price at settle #{price_at_settle}
        Won? #{won?}
        Won #{points_won} coins
        """)

        {:ok, won?, gas_cost, points_won}

      {:error, :no_price_information} ->
        Logger.error("cannot settle bet")
        {:error, :can_not_settle}

      {:error, err} ->
        {:error, err}
    end
  end

  # check if there is enough pricing information to settle this bet
  # and if the user has enough coins to make the bet
  @spec can_settle?(Bet.t()) ::
          {:error, :no_price_information} | {:ok, {float(), float(), DateTime.t()}}
  defp can_settle?(bet) do
    with %Currency{price: btc_price_at_bet} <- Anoma.Pricing.price_at("BTC-USD", bet.inserted_at),
         settle_time <- DateTime.add(bet.inserted_at, 1, :minute),
         %Currency{price: btc_price_now} <- Anoma.Pricing.price_at("BTC-USD", settle_time) do
      # check that the user has enough coins to make this bet
      required_points = bet.points
      required_gas = :math.pow(bet.multiplier, 2) * 10

      cond do
        required_points > bet.user.points ->
          {:error, :not_enough_points}

        required_gas > bet.user.gas ->
          {:error, :not_enough_gas}

        true ->
          {:ok, {btc_price_at_bet, btc_price_now, settle_time}}
      end
    else
      _ ->
        {:error, :no_price_information}
    end
  end
end
