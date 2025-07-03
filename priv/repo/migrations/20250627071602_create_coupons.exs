defmodule Anoma.Repo.Migrations.CreateGarapon do
  use Ecto.Migration

  def change do
    create table(:coupons, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add :owner_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :used, :boolean, default: false
      timestamps(type: :utc_datetime)
    end

    create index(:coupons, [:owner_id])
  end
end
