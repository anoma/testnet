# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Anoma.Repo.insert!(%Anoma.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Script for populating the database with invite codes
alias Anoma.Accounts
alias Anoma.Invites

invites = 1
users = 1

if Mix.env() == :dev do
  # Function to generate a unique invite code
  defmodule Generator do
    def generate_code do
      # Generate a random string of 8 characters
      random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
      # Add timestamp to ensure uniqueness
      timestamp = DateTime.utc_now() |> DateTime.to_unix()
      # Combine and format
      "INV-#{random}-#{timestamp}"
    end

    def generate_user do
      Accounts.create_user()
    end
  end

  # generate the users
  for _ <- 1..users do
    {:ok, user} = Generator.generate_user()

    # generate ivites for user
    for _ <- 1..invites do
      code = Generator.generate_code()
      {:ok, invite} = Invites.create_invite(%{code: code})
      Invites.assign_invite(invite, user)
    end
  end
end
