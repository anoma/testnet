defmodule Anoma.Repo.Migrations.AddPriceAtBet do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      add :price_at_bet, :float
      add :price_at_settle, :float
    end
  end
end
