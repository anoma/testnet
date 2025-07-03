defmodule Anoma.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Anoma.Accounts.User
  alias Anoma.Repo
  alias AnomaWeb.Twitter

  require Logger

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  @spec list_users() :: [User.t()]
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(binary()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user.

  Returns {:ok, user} or {:error, :not_found}

  ## Examples

      iex> get_user(123)
      User{}

      iex> get_user(456)
      {:error, :not_found}

  """
  @spec get_user(binary()) :: User.t() | nil
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a user by Twitter ID.

  ## Examples

      iex> get_user_by_twitter_id("123456789")
      %User{}

      iex> get_user_by_twitter_id("nonexistent")
      nil

  """
  @spec get_user_by_twitter_id(String.t()) :: User.t() | nil
  def get_user_by_twitter_id(twitter_id) do
    Repo.get_by(User, twitter_id: twitter_id)
  end

  @doc """
  Creates a basic user with minimal required fields.

  ## Examples

      iex> create_basic_user()
      {:ok, %User{}}

  """
  @spec create_basic_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_basic_user(attrs \\ %{}) do
    default_attrs = %{
      points: 0,
      confirmed_at: DateTime.utc_now()
    }

    attrs = Map.merge(default_attrs, attrs)

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Adds Twitter data to an existing user or creates a new user if Twitter ID doesn't exist.

  ## Examples

      iex> add_twitter_data(%{twitter_id: "123", twitter_username: "user", ...})
      {:ok, %User{}}

  """
  @spec create_or_update_user_with_twitter_data(Twitter.user_meta_data(), String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_user_with_twitter_data(twitter_data, access_token) do
    case get_user_by_twitter_id(twitter_data.id) do
      nil ->
        create_user_with_twitter_data(twitter_data, access_token)

      existing_user ->
        update_user_twitter_data(existing_user, twitter_data, access_token)
    end
  end

  @spec create_user_with_twitter_data(Twitter.user_meta_data(), String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user_with_twitter_data(twitter_data, access_token) do
    attrs = %{
      # twitter data
      twitter_id: twitter_data.id,
      twitter_username: twitter_data.username,
      twitter_name: twitter_data.name,
      twitter_avatar_url: twitter_data.profile_image_url,
      twitter_bio: twitter_data.description,
      twitter_verified: twitter_data.verified || false,
      twitter_public_metrics: twitter_data.public_metrics,
      # other data
      auth_provider: "twitter",
      auth_token: access_token,
      points: 0,
      confirmed_at: DateTime.utc_now()
    }

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_user_twitter_data(User.t(), Twitter.user_meta_data(), String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user_twitter_data(user, twitter_data, access_token) do
    attrs = %{
      # twitter data
      twitter_id: twitter_data.id,
      twitter_username: twitter_data.username,
      twitter_name: twitter_data.name,
      twitter_avatar_url: twitter_data.profile_image_url,
      twitter_bio: twitter_data.description,
      twitter_verified: twitter_data.verified || false,
      twitter_public_metrics: twitter_data.public_metrics,
      # other data
      auth_provider: "twitter",
      auth_token: access_token
    }

    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user's ETH address.

  ## Examples

      iex> update_user_eth_address(user, "0x1234...")
      {:ok, %User{}}

      iex> update_user_eth_address(user, invalid_address)
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_eth_address(User.t(), String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user_eth_address(%User{} = user, eth_address) do
    user
    |> User.changeset(%{eth_address: eth_address})
    |> Repo.update()
  end

  @doc """
  Adds points to a user's account.

  ## Examples

      iex> add_points_to_user(user, 100)
      {:ok, %User{}}

      iex> add_points_to_user(user, -50)
      {:ok, %User{}}

  """
  @spec add_points_to_user(User.t(), integer()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def add_points_to_user(%User{} = user, points) when is_integer(points) do
    current_points = user.points || 0
    new_points = current_points + points

    user
    |> User.changeset(%{points: new_points})
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user(User.t(), map()) :: Ecto.Changeset.t()
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Creates or updates a user based on their Ethereum address.

  ## Examples

      iex> create_or_update_user_with_eth_address("0x1234...")
      {:ok, %User{}}

  """
  @spec create_or_update_user_with_eth_address(String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_user_with_eth_address(eth_address) do
    case Repo.get_by(User, eth_address: eth_address) do
      nil ->
        create_user_with_eth_address(eth_address)

      existing_user ->
        {:ok, existing_user}
    end
  end

  @spec create_user_with_eth_address(String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp create_user_with_eth_address(eth_address) do
    attrs = %{
      eth_address: eth_address,
      auth_provider: "metamask",
      points: 0,
      confirmed_at: DateTime.utc_now()
    }

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end


end
