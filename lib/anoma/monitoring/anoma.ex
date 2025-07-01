defmodule Anoma.PromEx.Users do
  @moduledoc """
  Defines a list of custom metrics about the Anoma platform.
  """
  use PromEx.Plugin

  @impl true
  def polling_metrics(_opts) do
    Polling.build(
      :anoma_invites,
      1000,
      {__MODULE__, :open_invites, []},
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
          [:anoma, :user, :gas],
          event_name: [:anoma, :user, :user_info],
          description: "Gas per user",
          measurement: :gas,
          tags: [:id]
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
        )
      ]
    )
  end

  def open_invites do
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
    |> Anoma.Repo.preload(invites: [:invitee])
    |> Enum.each(fn user ->
      :telemetry.execute(
        [:anoma, :user, :user_info],
        %{
          gas: user.gas,
          points: user.points,
          fitcoins: user.fitcoins,
          invites: Enum.count(user.invites),
          used_invites: Enum.count(user.invites, fn invite -> invite.invitee != nil end)
        },
        %{
          id: user.id
        }
      )
    end)
  end
end
