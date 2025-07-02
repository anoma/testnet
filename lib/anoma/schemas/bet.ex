defmodule Anoma.Pricing.Bet do
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
      points: %Schema{type: :integer, description: "Points bet"},
      settled: %Schema{type: :boolean, description: "Has the bet been settled?"},
      user_id: %Schema{type: :string, description: "ID of the user who placed this bet"}
    },
    required: [:name, :email],
    example: %{
      "id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
      "up" => true,
      "points" => 1,
      "multiplier" => 1,
      "user_id" => "296d3862-d189-4add-ada5-b346b1df406a",
      "settled" => false
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:__meta__, :__struct__, :user, :inserted_at, :updated_at]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "bets" do
    @derive {Jason.Encoder, except: @json_fields}
    field :up, :boolean, default: false
    field :multiplier, :integer
    field :points, :integer
    field :settled, :boolean, default: false
    belongs_to :user, Anoma.Accounts.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:up, :multiplier, :points, :user_id, :inserted_at])
    |> validate_required([:up, :multiplier, :points, :user_id])
  end
end
