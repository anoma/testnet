defmodule Anoma.Accounts.User do
  @moduledoc """
  Schema that represents a single user in the application.
  """
  use Ecto.Schema
  use TypedEctoSchema

  import Ecto.Changeset
  alias OpenApiSpex.Schema

  # ----------------------------------------------------------------------------
  # OpenAPI Schema

  @schema %Schema{
    title: "User",
    description: "A user",
    type: :object,
    properties: %{
      id: %Schema{type: :integer, description: "User id"},
      eth_address: %Schema{type: :string, description: "User their ethereum address"},
      gas: %Schema{type: :integer, description: "Total gas the user has"},
      points: %Schema{type: :integer, description: "Total points the user has"},
      fitcoins: %Schema{type: :integer, description: "Total fitcoins the user has"}
    },
    required: [:name, :email],
    example: %{
      "id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
      "points" => 1,
      "gas" => 1,
      "eth_address" => "0xDEADBEEF",
      "fitcoins" => 1234
    },
    "x-struct": __MODULE__
  }

  def schema, do: @schema

  # ----------------------------------------------------------------------------
  # Schema

  @json_fields [:id, :eth_address, :gas, :points, :fitcoins]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "users" do
    @derive {Jason.Encoder, only: @json_fields}
    field :email, :string
    field :confirmed_at, :utc_datetime
    field :points, :integer, default: 0
    field :gas, :integer, default: 0
    field :eth_address, :string

    # Fitcoin
    field :fitcoins, :integer, default: 0

    # Twitter fields (optional)
    field :twitter_id, :string
    field :twitter_username, :string
    field :twitter_name, :string
    field :twitter_avatar_url, :string
    field :twitter_bio, :string
    field :twitter_verified, :boolean, default: false
    field :twitter_public_metrics, :map
    field :auth_provider, :string
    field :auth_token, :string

    # has_one :invite, Anoma.Accounts.Invite

    # invites available to this user
    has_many :invites, Anoma.Accounts.Invite, foreign_key: :owner_id

    # a user can have many bets
    has_many :bets, Anoma.Pricing.Bet, foreign_key: :user_id

    has_one :invite, Anoma.Accounts.Invite, foreign_key: :invitee_id

    has_many :daily_points, Anoma.Accounts.DailyPoint

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :auth_provider,
      :auth_token,
      :confirmed_at,
      :email,
      :eth_address,
      :points,
      :gas,
      :twitter_avatar_url,
      :twitter_bio,
      :twitter_id,
      :twitter_name,
      :twitter_public_metrics,
      :twitter_username,
      :twitter_verified,
      :fitcoins
    ])
    |> validate_twitter_fields()
    |> unique_constraint(:twitter_id)
    |> unique_constraint(:twitter_username)
    |> unique_constraint(:eth_address)
  end

  # ----------------------------------------------------------------------------
  # Helpers

  defp validate_twitter_fields(changeset) do
    # If twitter_id is provided, require twitter_username as well
    case get_field(changeset, :twitter_id) do
      nil ->
        changeset

      _twitter_id ->
        changeset
        |> validate_required([:twitter_id, :twitter_username])
    end
  end
end
