defmodule Anoma.DailyPoints.DailyPoint do
  @moduledoc """
  Schema for a daily point that a user can claim.
  """
  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "Daily Point",
    description: "A daily point the user can find scattered around the map",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "Daily Point ID"},
      location: %Schema{type: :boolean, description: "Hash of the location of the point"},
      day: %Schema{type: :integer, description: "Day the point is discoverable"},
      claimed: %Schema{type: :integer, description: "Has this point been found by the user?"}
    },
    required: [:name, :email],
    example: %{
      "id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
      "location" => "DEADBEEF",
      "day" => "2025-07-02",
      "claimed" => false
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:__meta__, :__struct__, :user, :inserted_at, :updated_at, :user_id]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "daily_points" do
    @derive {Jason.Encoder, except: @json_fields}

    field :location, :string
    field :day, :date
    field :claimed, :boolean, default: false
    belongs_to :user, Anoma.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(daily_point, attrs) do
    daily_point
    |> cast(attrs, [:location, :day, :claimed, :user_id])
    |> validate_required([:location, :day, :user_id])
  end
end
