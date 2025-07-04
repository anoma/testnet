defmodule Anoma.Pointlog do
  @moduledoc """
  The point log context.
  """
  import Ecto.Query, warn: false

  alias Anoma.Accounts.User
  alias Anoma.Pointlog.Entry
  alias Anoma.Repo

  @doc """
  Returns the list of point log entries.
  """
  @spec list_entries() :: [Entry.t()]
  def list_entries do
    Repo.all(Entry)
  end

  @spec create_point_entry(number(), User.t(), User.t()) :: {:ok, Entry.t()} | {:error, term()}
  def create_point_entry(amount, from_id, to_id) do
    %Entry{}
    |> Entry.changeset(%{sender_id: from_id, receiver_id: to_id, amount: amount})
    |> Repo.insert()
  end

  def points_obtained_by(user_id, other_user_id) do
    Entry
    |> where([e], e.receiver_id == ^user_id)
    |> where([e], e.sender_id == ^other_user_id)
    |> select([e], sum(e.amount))
    |> Repo.one()
    |> case do
      nil ->
        0

      num ->
        num
    end
  end
end
