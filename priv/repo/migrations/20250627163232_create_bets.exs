defmodule Anoma.Repo.Migrations.CreateBets do
  use Ecto.Migration

  def change do
    create table(:bets, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add :up, :boolean, default: false, null: false
      add :multiplier, :integer
      add :points, :integer
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :settled, :boolean, default: false
      timestamps(type: :utc_datetime)
    end
  end
end
