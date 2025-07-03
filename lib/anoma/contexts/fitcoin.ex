defmodule Anoma.Fitcoin do
  @moduledoc """
  The Fitcoin context.
  """

  import Ecto.Query, warn: false

  alias Anoma.Accounts
  alias Anoma.Accounts.User
  alias Anoma.Repo

  require Logger

  @doc """
  Add 1 fitcoin to the given user
  """
  @spec add_fitcoin(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def add_fitcoin(%User{} = user) do
    user
    |> User.changeset(%{fitcoins: (user.fitcoins || 0) + 1})
    |> Repo.update()
  end

  @doc """
  Return the balance of fitcoins for the given user.
  """
  @spec balance(User.t()) :: {:ok, non_neg_integer()}
  def balance(%User{} = user) do
    with %User{} = user <- Accounts.get_user(user.id) do
      {:ok, user.fitcoins || 0}
    end
  end
end
