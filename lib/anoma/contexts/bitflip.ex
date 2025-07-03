defmodule Anoma.Bitflip do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false

  alias Anoma.Accounts
  alias Anoma.Accounts.User
  alias Anoma.Assets.Currency
  alias Anoma.Bitflip.Bet
  alias Anoma.Repo

  require Logger

  @doc """
  Returns the list of bitflip.

  ## Examples

      iex> list_bets()
      [%Bet{}, ...]

  """
  def list_bets do
    Repo.all(Bet)
  end

  @spec made_bets(User.t()) :: number()
  def made_bets(user) do
    user_id = user.id

    Bet
    |> where([b], b.user_id == ^user_id)
    |> select([b], count("*"))
    |> Repo.one()
  end

  @doc """
  Returns the list of bets that are not settled.

  ## Examples

      iex> list_unsettled_bets()
      [%Bet{}, ...]

  """
  def list_unsettled_bets do
    Bet
    |> where([b], b.settled == false)
    |> Repo.all()
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
  Places a bet for a user with the given parameters.
  """
  @spec place_bet(User.t(), boolean(), number(), number()) ::
          {:ok, Bet.t()} | {:error, :not_enough_fitcoins | :not_enough_points}
  def place_bet(user, up?, multiplier, points) do
    # compute the required fitcoins to place this bet
    required_fitcoins = (:math.pow(multiplier, 2) * 10) |> trunc()
    required_points = points

    Repo.transaction(fn ->
      # get the current bitcoin price
      current_price = Anoma.Assets.price_at("BTC-USD", DateTime.utc_now())

      # fetch the user to get the latest points
      user = Accounts.get_user!(user.id)

      # make sure the user has all the required points and fitcoins
      cond do
        current_price == nil ->
          Repo.rollback(:no_pricing_information)

        required_fitcoins > user.fitcoins ->
          Repo.rollback(:not_enough_fitcoins)

        required_points > user.points ->
          Repo.rollback(:not_enough_points)

        true ->
          # deduct the points from the user
          {:ok, user} =
            Accounts.update_user(user, %{
              points: user.points - required_points,
              fitcoins: user.fitcoins - required_fitcoins
            })

          # create the bet
          {:ok, bet} =
            create_bet(%{
              user_id: user.id,
              up: up?,
              points: points,
              multiplier: multiplier,
              price_at_bet: current_price.price
            })

          bet
      end
    end)
  end

  @doc """
  I settle a bet if its possible.
  """
  @spec settle_bet(Bet.t()) ::
          {:ok, Bet.t(), :won | :lost} | {:error, :already_settled} | {:error, term()}
  def settle_bet(%Bet{} = bet) do
    Logger.warning("settling bet #{inspect(bet)}")
    bet = Repo.preload(bet, :user)
    user = bet.user
    # if the user won, update their balance.
    case won?(bet) do
      {:ok, :won, profit, price_at_settle} ->
        Logger.warning("bet won")
        {:ok, _user} = Accounts.add_points_to_user(user, profit)

        {:ok, bet} =
          update_bet(bet, %{settled: true, won: true, price_at_settle: price_at_settle})

        {:ok, bet, :won}

      {:ok, :lost, price_at_settle} ->
        Logger.warning("bet lost")

        {:ok, bet} =
          update_bet(bet, %{settled: true, won: false, price_at_settle: price_at_settle})

        {:ok, bet, :lost}

      {:error, err} ->
        Logger.warning("bet error #{inspect(err)}")
        {:error, err}
    end

    # mark the transaction as settled
  end

  # ----------------------------------------------------------------------------#
  #                                Helpers                                     #
  # ----------------------------------------------------------------------------#

  # check if the bet is won
  @spec won?(Bet.t()) ::
          {:ok, :won, number(), number()}
          | {:ok, :lost, number()}
          | {:error, :already_settled}
          | {:error, term()}
  defp won?(bet) do
    with bet <- Repo.preload(bet, :user),
         {:ok, end_price} <- has_price_info?(bet) do
      # calculate the profit
      profit = (bet.multiplier + 1) * bet.points

      # check if the bet is won
      cond do
        bet.settled ->
          {:error, :already_settled}

        bet.up and bet.price_at_bet < end_price ->
          {:ok, :won, profit, end_price}

        true ->
          {:ok, :lost, end_price}
      end
    else
      {:error, err} ->
        {:error, err}
    end
  end

  # check if there is enough price info to settle this bet
  @spec has_price_info?(Bet.t()) :: {:ok, float()} | {:error, :no_price_information}
  defp has_price_info?(bet) do
    with settle_time <- DateTime.add(bet.inserted_at, 1, :minute),
         %Currency{price: btc_price_now} <- Anoma.Assets.price_at("BTC-USD", settle_time) do
      {:ok, btc_price_now}
    else
      _ ->
        {:error, :no_price_information}
    end
  end
end
