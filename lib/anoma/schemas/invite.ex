defmodule Anoma.Accounts.Invite do
  @moduledoc """
  Schema for an invite owned by a user.
  """
  use Ecto.Schema
  use TypedEctoSchema

  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "Invite",
    description: "An invite for the Anoma testnet",
    type: :object,
    properties: %{
      code: %Schema{type: :string, description: "Invite code"},
      claimed?: %Schema{type: :boolean, description: "Has the invite been used?"},
      invitee_id: %Schema{type: :string, description: "User id of the invitee"}
    },
    required: [:name, :email],
    example: %{
      "code" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
      "claimed?" => true,
      "invitee_id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950"
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:__meta__, :__struct__, :owner, :invitee]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "invites" do
    @derive {Jason.Encoder, except: @json_fields}
    field :code, :string
    belongs_to :owner, Anoma.Accounts.User

    belongs_to :invitee, Anoma.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:code])
    |> validate_required([:code])
    |> unique_constraint(:code)
  end
end
