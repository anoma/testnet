defmodule Anoma.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Anoma.Accounts` context.
  """
  alias Anoma.Accounts
  alias Anoma.DailyPoints
  alias Anoma.Invites

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        confirmed_at: ~U[2025-06-11 12:43:00Z],
        email: "some email",
        eth_address: Base.encode16(:crypto.strong_rand_bytes(20)),
        points: 42
      })
      |> Accounts.create_user()

    user
  end

  @doc """
  Generate a invite.
  """
  def invite_fixture(attrs \\ %{}) do
    {:ok, invite} =
      attrs
      |> Enum.into(%{
        code: "some code"
      })
      |> Invites.create_invite()

    invite
  end

  @doc """
  Generate a daily_point.
  """
  def daily_point_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()

    {:ok, daily_point} =
      attrs
      |> Enum.into(%{
        location: :crypto.strong_rand_bytes(64) |> Base.encode16(),
        day: Date.utc_today(),
        claimed: false,
        user_id: user.id
      })
      |> DailyPoints.create_daily_point()

    DailyPoints.get_daily_point!(daily_point.id)
  end
end
