defmodule Anoma.Bitflip.Bet do
  @moduledoc """
  Represent a bet that can be placed on the bitcoin price.
  """
  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "Bet",
    description: "A bet placed by a user",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Bet ID"},
      up: %Schema{type: :boolean, description: "Will the price go up?"},
      multiplier: %Schema{type: :integer, description: "Multiplier on the bet"},
      price_at_bet: %Schema{type: :float, description: "Price when the bet was made"},
      price_at_settle: %Schema{type: :float, description: "Price when the bet was settled"},
      points: %Schema{type: :integer, description: "Points bet"},
      settled: %Schema{type: :boolean, description: "Has the bet been settled?"},
      won: %Schema{type: :boolean, description: "Did the user win the bet?"},
      user_id: %Schema{type: :string, description: "ID of the user who placed this bet"},
      inserted_at: %Schema{
        type: :string,
        description: "Time the bet was placed",
        format: :datetime
      }
    },
    required: [:name, :email],
    example: %{
      "id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
      "up" => true,
      "points" => 1,
      "multiplier" => 1,
      "price_at_bet" => 123.456,
      "price_at_settle" => 123.456,
      "user_id" => "296d3862-d189-4add-ada5-b346b1df406a",
      "settled" => false,
      "won" => false,
      "inserted_at" => "2025-07-02T12:41:40Z"
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:__meta__, :__struct__, :user, :updated_at]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "bets" do
    @derive {Jason.Encoder, except: @json_fields}
    field :up, :boolean, default: false
    field :multiplier, :integer
    field :points, :integer
    field :settled, :boolean, default: false
    field :won, :boolean
    field :price_at_bet, :float
    field :price_at_settle, :float
    belongs_to :user, Anoma.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [
      :up,
      :multiplier,
      :points,
      :user_id,
      :inserted_at,
      :settled,
      :won,
      :price_at_bet,
      :price_at_settle
    ])
    |> validate_required([:up, :multiplier, :points, :user_id])
  end
end
