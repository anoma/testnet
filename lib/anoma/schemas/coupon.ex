defmodule Anoma.Garapon.Coupon do
  @moduledoc """
  Schema for a garapon coupon that a user can use in the daily lottery.
  """
  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "Coupon",
    description: "Garapon coupon for the lottery",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Coupon ID", example: "12345"},
      used: %Schema{type: :boolean, description: "Has the coupon been used?", example: true},
      prize: %Schema{type: :string, description: "What has been won?", example: "fitcoin"},
      prize_amount: %Schema{
        type: :integer,
        description: "How many of `prize` have been won?",
        example: "120"
      }
    },
    required: [:name, :email],
    "x-struct": Anoma.Garapon.Coupon
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "coupons" do
    @derive {Jason.Encoder,
             except: [:__meta__, :__struct__, :owner, :owner_id, :inserted_at, :updated_at]}
    # a coupon belongs to a user
    belongs_to :owner, Anoma.Accounts.User

    field :prize, :string
    field :prize_amount, :integer

    # whether the coupon is used or not
    field :used, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(coupon, attrs) do
    coupon
    |> cast(attrs, [:owner_id, :used, :prize, :prize_amount])
    |> validate_required([:owner_id])
  end
end
