defmodule Anoma.PromEx.Users do
  @moduledoc """
  Defines a list of custom metrics about the Anoma platform.
  """
  use PromEx.Plugin

  @impl true
  def polling_metrics(_opts) do
    Polling.build(
      :anoma_stats,
      1000,
      {__MODULE__, :anoma_stats, []},
      [
        # Capture information regarding the primary application (i.e the user's application)
        last_value(
          [:anoma, :invites, :count],
          event_name: [:anoma, :invites, :count],
          description: "Amount of invites that are used",
          measurement: :count,
          tags: [:status]
        ),
        last_value(
          [:anoma, :users, :count],
          event_name: [:anoma, :users, :count],
          description: "Amount registered users",
          measurement: :count,
          tags: [:status]
        ),
        last_value(
          [:anoma, :user, :points],
          event_name: [:anoma, :user, :user_info],
          description: "Points per user",
          measurement: :points,
          tags: [:id]
        ),
        last_value(
          [:anoma, :user, :fitcoins],
          event_name: [:anoma, :user, :user_info],
          description: "Fitcoins per user",
          measurement: :fitcoins,
          tags: [:id]
        ),
        last_value(
          [:anoma, :user, :invites],
          event_name: [:anoma, :user, :user_info],
          description: "Invites per user",
          measurement: :invites,
          tags: [:id]
        ),
        last_value(
          [:anoma, :user, :used_invites],
          event_name: [:anoma, :user, :user_info],
          description: "Sent invites per user",
          measurement: :used_invites,
          tags: [:id]
        ),
        last_value(
          [:anoma, :user, :made_bets],
          event_name: [:anoma, :user, :user_info],
          description: "Amount of bets made by a user",
          measurement: :bets,
          tags: [:id]
        ),
        last_value(
          [:anoma, :user, :used_coupons],
          event_name: [:anoma, :user, :user_info],
          description: "Amount of used coupons by a user",
          measurement: :used_coupons,
          tags: [:id]
        ),
        last_value(
          [:anoma, :stats, :users],
          event_name: [:anoma, :stats, :users],
          description: "Active users in the last hours",
          measurement: :active_users,
          tags: [:range]
        )
      ]
    )
  end

  def anoma_stats do
    # PromEx has to start before the repo, so the repo might not always be online.
    anoma_repo_pid = Process.whereis(Anoma.Repo)

    if anoma_repo_pid != nil do
      %{used: used, unused: unused} = Anoma.Invites.open_invites()

      # emit the total invite count for used and unused
      :telemetry.execute(
        [:anoma, :invites, :count],
        %{
          count: used
        },
        %{
          status: "used"
        }
      )

      :telemetry.execute(
        [:anoma, :invites, :count],
        %{
          count: unused
        },
        %{
          status: "unused"
        }
      )

      # emit the total amount of users
      :telemetry.execute(
        [:anoma, :users, :count],
        %{
          count: Enum.count(Anoma.Accounts.list_users())
        },
        %{
          status: "unused"
        }
      )

      # emit metrics per user
      Anoma.Accounts.list_users()
      |> Anoma.Repo.preload([:bets, invites: [:invitee]])
      |> Enum.each(fn user ->
        {used_coupons, unused_coupons} = Anoma.Garapon.count_coupons(user)

        :telemetry.execute(
          [:anoma, :user, :user_info],
          %{
            points: user.points,
            fitcoins: user.fitcoins,
            invites: Enum.count(user.invites),
            used_invites: Enum.count(user.invites, fn invite -> invite.invitee != nil end),
            bets: Anoma.Bitflip.made_bets(user),
            unused_coupons: unused_coupons,
            used_coupons: used_coupons
          },
          %{
            id: user.id
          }
        )
      end)

      for hours <- [24, 12, 6, 1] do
        :telemetry.execute(
          [:anoma, :stats, :users],
          %{
            active_users: Anoma.Accounts.active_last_hour(hours)
          },
          %{
            range: hours
          }
        )
      end
    end
  end
end
