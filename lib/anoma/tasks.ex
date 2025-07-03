defmodule Anoma.Tasks do
  @moduledoc """
  Defines a few functions that are being run as a task by the Quantum scheduler.
  """
  alias Anoma.DailyPoints.DailyPoints
  alias Anoma.Invites

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
  Settle all outstanding bitflip.
  """
  def settle_bets do
    Logger.warning("settling bets")

    Anoma.Bitflip.list_unsettled_bets()
    |> Enum.each(&Anoma.Bitflip.settle_bet/1)
  end

  @doc """
  Create a coupon for each user.
  """
  def create_daily_coupons do
    Anoma.Accounts.list_users()
    |> Enum.each(fn user ->
      {:ok, _coupon} =
        Anoma.Garapon.create_coupon(%{
          owner_id: user.id
        })
    end)
  end
end
