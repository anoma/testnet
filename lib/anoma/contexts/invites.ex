defmodule Anoma.Invites do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Anoma.Accounts
  alias Anoma.Accounts.Invite
  alias Anoma.Accounts.User
  alias Anoma.Repo

  require Logger

  @doc """
  Returns the number of unused invites and used invites.
  """
  @spec open_invites :: %{used: number(), unused: number()}
  def open_invites do
    Anoma.Invites.list_invites()
    |> Enum.group_by(&if &1.invitee == nil, do: :unused, else: :used)
    |> Map.put_new(:used, [])
    |> Map.put_new(:unused, [])
    |> Enum.map(fn {k, v} -> {k, Enum.count(v)} end)
    |> Enum.into(%{})
  end

  @doc """
  Returns the list of invites.

  ## Examples

      iex> list_invites()
      [%Invite{}, ...]

  """
  @spec list_invites() :: [Invite.t()]
  def list_invites do
    Repo.all(Invite)
  end

  @doc """
  Retrieves an invite based on its code.

  ## Examples

      iex> get_invite_by_code!("INV-123456789")
      %Invite{}

      iex> get_invite_by_code!("nonexistent")
      nil
  """
  @spec get_invite_by_code!(String.t()) :: Invite.t()
  def get_invite_by_code!(code) do
    Repo.get_by!(Invite, code: code)
  end

  @doc """
  Retrieves an invite based on its code.

  ## Examples

      iex> get_invite_by_code!("INV-123456789")
      %Invite{}

      iex> get_invite_by_code!("nonexistent")
      nil
  """
  @spec get_invite_by_code(String.t()) :: {:ok, Invite.t()} | {:error, :invite_not_found}
  def get_invite_by_code(code) do
    case Repo.get_by(Invite, code: code) do
      %Invite{} = invite ->
        {:ok, invite}

      nil ->
        {:error, :invite_not_found}
    end
  end

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123)
      %Invite{}

      iex> get_invite!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_invite!(binary()) :: Invite.t()
  def get_invite!(id), do: Repo.get!(Invite, id)

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%{field: value})
      {:ok, %Invite{}}

      iex> create_invite(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_invite(map()) :: {:ok, Invite.t()} | {:error, Ecto.Changeset.t()}
  def create_invite(attrs \\ %{}) do
    %Invite{}
    |> Invite.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a invite.

  ## Examples

      iex> update_invite(invite, %{field: new_value})
      {:ok, %Invite{}}

      iex> update_invite(invite, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_invite(Invite.t(), map()) :: {:ok, Invite.t()} | {:error, Ecto.Changeset.t()}
  def update_invite(%Invite{} = invite, attrs) do
    invite
    |> Invite.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Claims an invite for a user.

  ## Examples

      iex> claim_invite(invite, user)
      {:ok, %Invite{}}

      iex> claim_invite(invite, user)
      {:error, %Ecto.Changeset{}}
  """
  @spec claim_invite(Invite.t(), User.t()) :: {:ok, Invite.t()} | {:error, atom()}
  def claim_invite(%Invite{} = invite, %User{} = user) do
    Repo.transaction(fn ->
      # ensure invite is not claimed
      invite = get_invite!(invite.id)
      user = Accounts.get_user!(user.id) |> Repo.preload(:invite)

      cond do
        user.invite != nil ->
          Repo.rollback(:user_already_invited)

        invite.invitee_id != nil ->
          Repo.rollback(:invite_already_claimed)

        true ->
          invite
          |> Repo.preload(:invitee)
          |> Invite.changeset(%{})
          |> Ecto.Changeset.put_assoc(:invitee, user)
          |> Repo.update()
      end
    end)
    |> case do
      {:ok, res} ->
        res

      err ->
        err
    end
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite)
      {:ok, %Invite{}}

      iex> delete_invite(invite)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_invite(Invite.t()) :: {:ok, Invite.t()} | {:error, Ecto.Changeset.t()}
  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Ecto.Changeset{data: %Invite{}}

  """
  @spec change_invite(Invite.t(), map()) :: Ecto.Changeset.t()
  def change_invite(%Invite{} = invite, attrs \\ %{}) do
    Invite.changeset(invite, attrs)
  end

  @doc """
  Returns the list of invites associated to the given user.

  ## Examples

      iex> invites_for(user)
      [%Invite{}]

  """
  @spec invites_for(User.t()) :: [Invite.t()]
  def invites_for(%User{} = user) do
    user
    |> Repo.preload(:invites)
    |> Map.get(:invites)
  end

  @doc """
  Assigns an existing invite to an existing user.
  """
  @spec assign_invite(Invite.t(), User.t()) :: {:ok, Invite.t()} | {:error, atom()}
  def assign_invite(invite, user) do
    Repo.transaction(fn ->
      # fetch the invite to have the latest version
      invite = get_invite!(invite.id) |> Repo.preload(:owner)

      # ensure invite is not claimed by another user
      user = Accounts.get_user!(user.id)

      if invite.owner_id != nil do
        Repo.rollback(:invite_already_assigned)
      else
        invite
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:owner, user)
        |> Repo.update()
      end
    end)
    |> case do
      {:ok, res} ->
        res

      err ->
        err
    end
  end
end
