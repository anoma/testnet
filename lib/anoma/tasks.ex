defmodule Anoma.Tasks do
  @moduledoc """
  Defines a few functions that are being run as a task by the Quantum scheduler.
  """
  alias Anoma.Accounts.DailyPoints
  alias Anoma.Invites
  alias Anoma.Pricing.Currency

  require Logger

  @doc """
  Create new rewards for all users
  """
  @daily_rewards 3
  def create_daily_rewards do
    Anoma.Accounts.list_users()
    |> Enum.flat_map(fn user ->
      # verify user has no dailies
      daily_points = DailyPoints.get_user_daily_points(user)

      if Enum.count(daily_points) >= 3 do
        []
      else
        for _ <- 1..@daily_rewards do
          attrs = %{
            user_id: user.id,
            location: Base.encode16(:crypto.strong_rand_bytes(64)),
            day: Date.utc_today()
          }

          {:ok, point} = DailyPoints.create_daily_point(attrs)
          point
        end
      end
    end)
  end

  @invite_count 10
  @doc """
  Generate invites for users.
  """
  def generate_invites do
    Anoma.Accounts.list_users()
    |> Enum.each(fn user ->
      invites = Invites.invites_for(user)

      for _ <- 1..(@invite_count - Enum.count(invites)) do
        code = Base.encode16(:crypto.strong_rand_bytes(8))
        {:ok, invite} = Invites.create_invite(%{code: code})
        Invites.assign_invite(invite, user)
      end
    end)
  end

  @doc """
  Settle all outstanding bets.
  """
  def settle_bets do
    Anoma.Bets.list_bets()
    |> Enum.each(fn bet ->
      # fetch the user of the bet
      bet = Anoma.Repo.preload(bet, :user)
      # first check if this bet can be settled.
      # i.e., is there enough pricing info available
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

          points_won = bet.points * bet.multiplier

          Logger.debug("""

          Bet made at     #{bet.inserted_at}
          Bet settle at   #{settle_time}
          Price at bet    #{price_at_bet}
          Price at settle #{price_at_settle}
          Won? #{won?}
          Won #{points_won} coins
          """)

        {:error, :no_price_information} ->
          Logger.error("cannot settle bet")
      end
    end)
  end

  # check if there is enough pricing information to settle this bet
  defp can_settle?(bet) do
    with %Currency{price: btc_price_at_bet} <- Anoma.Pricing.price_at("BTC-USD", bet.inserted_at),
         settle_time <- DateTime.add(bet.inserted_at, 1, :minute),
         %Currency{price: btc_price_now} <- Anoma.Pricing.price_at("BTC-USD", settle_time) do
      # check that the user has enough coins to make this bet
      required_points = bet.points
      required_gas = :math.pow(bet.multiplier, 2) * 10

      cond do
        required_points < bet.user.points ->
          {:error, :not_enough_points}

        required_gas < bet.user.gas ->
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
