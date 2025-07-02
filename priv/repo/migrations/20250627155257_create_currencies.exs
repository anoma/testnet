defmodule Anoma.Repo.Migrations.CreateCurrencies do
  use Ecto.Migration

  def change do
    create table(:currencies) do
      add :price, :float
      add :currency, :string
      add :timestamp, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
