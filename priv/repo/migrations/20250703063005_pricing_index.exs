defmodule Anoma.Repo.Migrations.PricingIndex do
  use Ecto.Migration

  def change do
    create index(:bets, [:user_id])
    create index(:bets, [:settled])

    create index(:currencies, [:timestamp])
    create unique_index(:currencies, [:timestamp, :currency])

    create index(:coupons, [:used])

    create index(:daily_points, [:day])
    create index(:daily_points, [:claimed])

    create index(:users, [:id])
  end
end
