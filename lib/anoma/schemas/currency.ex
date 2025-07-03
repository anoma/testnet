defmodule Anoma.Assets.Currency do
  @moduledoc """
  I implement the schema for a currency value.
  """
  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "Currency",
    description: "The value of an asset at a given point in time.",
    type: :object,
    properties: %{
      currency: %Schema{type: :string, description: "Name of the asset"},
      price: %Schema{type: :float, description: "Price"},
      timestamp: %Schema{type: :string, description: "Time of the value", format: :datetime}
    },
    required: [:name, :email],
    example: %{
      "currency" => "BTC-USD",
      "timestamp" => "2025-07-02T12:41:40Z",
      "price" => "123.456"
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:__meta__, :__struct__, :inserted_at, :updated_at]

  typed_schema "currencies" do
    @derive {Jason.Encoder, except: @json_fields}
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
