defmodule Anoma.Pointlog.Entry do
  @moduledoc """
  Represent an entry in the point log for a user.
  """
  use Ecto.Schema
  use TypedEctoSchema
  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "Point Log",
    description: "A log entry for a user's point change",
    type: :object,
    properties: %{
      sender_id: %Schema{type: :string, description: "ID of the user who sent these points."},
      receiver_id: %Schema{
        type: :boolean,
        description: "ID of the user who received these points."
      },
      amount: %Schema{type: :integer, description: "Amount of points received"},
      inserted_at: %Schema{
        type: :string,
        description: "Time the points were dedecuted or added",
        format: :datetime
      }
    },
    example: %{
      "sender_id" => "296d3862-d189-4add-ada5-b346b1df406a",
      "receiver_id" => "296d3862-d189-4add-ada5-b346b1df406a",
      "amount" => 1,
      "inserted_at" => "2025-07-02T12:41:40Z"
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:__meta__, :__struct__, :sender, :receiver, :updated_at]
  @primary_key false
  @foreign_key_type :binary_id

  typed_schema "point_log" do
    @derive {Jason.Encoder, except: @json_fields}
    belongs_to :sender, Anoma.Accounts.User
    belongs_to :receiver, Anoma.Accounts.User
    field :amount, :integer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:sender_id, :receiver_id, :amount])
    |> validate_required([:receiver_id, :amount])
  end
end
