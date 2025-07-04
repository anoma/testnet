defmodule Anoma.Repo.Migrations.PointLog do
  use Ecto.Migration

  def change do
    create table(:point_log, primary_key: false) do
      add :receiver_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :amount, :integer
      add :sender_id, references(:users, on_delete: :delete_all, type: :uuid)
      timestamps(type: :utc_datetime)
    end

    create index(:point_log, [:receiver_id])
    create index(:point_log, [:sender_id])
  end
end
