defmodule Anoma.Pricing.Currency do
  @moduledoc """
  I implement the schema for a currency value.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "currencies" do
    field :currency, :string
    field :price, :float
    field :timestamp, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:price, :currency, :timestamp])
    |> validate_required([:price, :currency, :timestamp])
  end
end
