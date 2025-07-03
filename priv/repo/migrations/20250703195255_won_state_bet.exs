defmodule Anoma.Repo.Migrations.WonStateBet do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      add :won, :boolean
    end
  end
end
