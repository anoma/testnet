defmodule Anoma.DailyPoints.DailyPoints do
  @moduledoc """
  The DailyPoints context.
  """

  import Ecto.Query, warn: false

  alias Anoma.DailyPoints.DailyPoint
  alias Anoma.Accounts.User
  alias Anoma.Repo

  require Logger

  @doc """
  Returns the list of daily points.

  ## Examples

      iex> list_daily_points()
      [%DailyPoint{}, ...]

  """
  @spec list_daily_points() :: [DailyPoint.t()]
  def list_daily_points do
    Repo.all(DailyPoint) |> Repo.preload(:user)
  end

  @doc """
  Gets a single daily_point.

  Raises `Ecto.NoResultsError` if the Daily point does not exist.

  ## Examples

      iex> get_daily_point!(123)
      %DailyPoint{}

      iex> get_daily_point!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_daily_point!(binary()) :: DailyPoint.t()
  def get_daily_point!(id) do
    Repo.get!(DailyPoint, id)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single daily_point.

  Returns {:ok, daily_point} if found, {:error, :not_found} otherwise.

  ## Examples

      iex> get_daily_point(123)
      {:ok, %DailyPoint{}}

      iex> get_daily_point(456)
      {:error, :not_found}

  """
  @spec get_daily_point(binary()) :: {:ok, DailyPoint.t()} | {:error, :not_found}
  def get_daily_point(id) do
    case Repo.get(DailyPoint, id) do
      nil -> {:error, :not_found}
      daily_point -> {:ok, Repo.preload(daily_point, :user)}
    end
  end

  @doc """
  Creates a daily_point.

  ## Examples

      iex> create_daily_point(%{field: value})
      {:ok, %DailyPoint{}}

      iex> create_daily_point(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_daily_point(map()) :: {:ok, DailyPoint.t()} | {:error, Ecto.Changeset.t()}
  def create_daily_point(attrs \\ %{}) do
    %DailyPoint{}
    |> DailyPoint.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a daily_point.

  ## Examples

      iex> update_daily_point(daily_point, %{field: new_value})
      {:ok, %DailyPoint{}}

      iex> update_daily_point(daily_point, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_daily_point(DailyPoint.t(), map()) ::
          {:ok, DailyPoint.t()} | {:error, Ecto.Changeset.t()}
  def update_daily_point(%DailyPoint{} = daily_point, attrs) do
    daily_point
    |> DailyPoint.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a daily_point.

  ## Examples

      iex> delete_daily_point(daily_point)
      {:ok, %DailyPoint{}}

      iex> delete_daily_point(daily_point)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_daily_point(DailyPoint.t()) :: {:ok, DailyPoint.t()} | {:error, Ecto.Changeset.t()}
  def delete_daily_point(%DailyPoint{} = daily_point) do
    Repo.delete(daily_point)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking daily_point changes.

  ## Examples

      iex> change_daily_point(daily_point)
      %Ecto.Changeset{data: %DailyPoint{}}

  """
  @spec change_daily_point(DailyPoint.t(), map()) :: Ecto.Changeset.t()
  def change_daily_point(%DailyPoint{} = daily_point, attrs \\ %{}) do
    DailyPoint.changeset(daily_point, attrs)
  end

  @doc """
  Gets daily points for a specific user.

  ## Examples

      iex> get_user_daily_points(user)
      [%DailyPoint{}, ...]

  """
  @spec get_user_daily_points(User.t()) :: [DailyPoint.t()]
  def get_user_daily_points(%User{} = user) do
    DailyPoint
    |> where([dp], dp.user_id == ^user.id)
    |> order_by([dp], desc: dp.day)
    |> preload([dp], [:user])
    |> Repo.all()
  end

  @doc """
  Gets daily points for a specific user and date.

  ## Examples

      iex> get_user_daily_points_by_date(user, ~D[2023-01-01])
      []

      iex> get_user_daily_points_by_date(user, ~D[2023-01-02])
      [%DailyPoint{}, ..]

  """
  @spec get_user_daily_points_by_date(User.t(), Date.t()) :: [DailyPoint.t()]
  def get_user_daily_points_by_date(%User{} = user, date) do
    DailyPoint
    |> where([dp], dp.user_id == ^user.id)
    |> where([dp], dp.day == ^date)
    |> order_by([dp], desc: dp.day)
    |> Repo.all()
  end

  @doc """
  Claims a daily point for a user on a specific date and location.

  ## Examples

      iex> claim_daily_point(user, ~D[2023-01-01], "DEADBEEF")
      {:ok, %DailyPoint{}}

      iex> claim_daily_point(user, ~D[2023-01-01], "DEADBEEF") # Already claimed
      {:error, %Ecto.Changeset{}}

  """
  @spec claim_daily_point(DailyPoint.t()) :: {:ok, DailyPoint.t()} | {:error, Ecto.Changeset.t()}
  def claim_daily_point(daily_point) do
    if daily_point.claimed do
      {:error, :already_claimed}
    else
      update_daily_point(daily_point, %{claimed: true})
    end
  end
end
