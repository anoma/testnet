defmodule Anoma.Pricing.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bets" do
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
    |> cast(attrs, [:up, :multiplier, :points, :user_id])
    |> validate_required([:up, :multiplier, :points, :user_id])
  end
end
