defmodule Anoma.Repo.Migrations.IndexOnUpdatedAt do
  use Ecto.Migration

  def change do
    create index(:users, [:updated_at])
    create index(:users, [:inserted_at])
  end
end
