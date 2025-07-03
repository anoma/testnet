defmodule Anoma.Garapon do
  @moduledoc """
  The Accounts.Garapon context.
  """

  import Ecto.Query, warn: false
  alias Anoma.Repo

  alias Anoma.Accounts
  alias Anoma.Accounts.User
  alias Anoma.Garapon
  alias Anoma.Garapon.Coupon

  @doc """
  Returns the list of coupons.

  ## Examples

      iex> list_coupons()
      [%Coupon{}, ...]

  """
  def list_coupons do
    Repo.all(Coupon)
  end

  @doc """
  Returns the list of coupons for the given user.

  ## Examples

      iex> list_coupons(user)
      [%Coupon{}, ...]

  """
  def list_coupons(%User{} = user) do
    Coupon
    |> where([dp], dp.owner_id == ^user.id)
    |> preload([dp], [:owner])
    |> Repo.all()
  end

  @doc """
  Returns the total amount of coupons this user has, that have not been used.
  """
  @spec count_coupons(User.t()) :: {number(), number()}
  def count_coupons(%User{} = user) do
    used =
      Coupon
      |> where([dp], dp.owner_id == ^user.id)
      |> where([dp], dp.used == true)
      |> Repo.aggregate(:count)

    unused =
      Coupon
      |> where([dp], dp.owner_id == ^user.id)
      |> where([dp], dp.used == true)
      |> Repo.aggregate(:count)

    {used, unused}
  end

  @doc """
  Gets a single coupon.

  Raises `Ecto.NoResultsError` if the Coupon does not exist.

  ## Examples

      iex> get_coupon!(123)
      %Coupon{}

      iex> get_coupon!(456)
      ** (Ecto.NoResultsError)

  """
  def get_coupon!(id), do: Repo.get!(Coupon, id)

  @doc """
  Creates a coupon.

  ## Examples

      iex> create_coupon(%{field: value})
      {:ok, %Coupon{}}

      iex> create_coupon(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_coupon(attrs \\ %{}) do
    %Coupon{}
    |> Coupon.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a coupon.

  ## Examples

      iex> update_coupon(coupon, %{field: new_value})
      {:ok, %Coupon{}}

      iex> update_coupon(coupon, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_coupon(%Coupon{} = coupon, attrs) do
    coupon
    |> Coupon.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a coupon.

  ## Examples

      iex> update_coupon(coupon, %{field: new_value})
      {:ok, %Coupon{}}

      iex> update_coupon(coupon, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def use_coupon(%Coupon{} = coupon) do
    Repo.transaction(fn ->
      # ensure invite is not claimed
      coupon = get_coupon!(coupon.id) |> Repo.preload(:owner)

      if coupon.used do
        Repo.rollback(:coupon_already_used)
      else
        # generate a random result for this coupon
        prize = [:points, :fitcoins, :coupons] |> Enum.shuffle() |> hd()
        prize_amount = (:rand.uniform_real() * 100) |> trunc()

        # update the user with the prize
        case prize do
          :points ->
            {:ok, _user} =
              Anoma.Accounts.add_points_to_user(coupon.owner, prize_amount)

          :fitcoins ->
            {:ok, _user} =
              Anoma.Accounts.update_user(coupon.owner, %{
                fitcoins: coupon.owner.fitcoins + prize_amount
              })

          :coupons ->
            for _ <- 1..prize_amount do
              {:ok, _coupon} =
                Garapon.create_coupon(%{
                  owner_id: coupon.owner.id
                })
            end
        end

        coupon
        |> Coupon.changeset(%{
          used: true,
          prize: Atom.to_string(prize),
          prize_amount: prize_amount
        })
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
  Deletes a coupon.

  ## Examples

      iex> delete_coupon(coupon)
      {:ok, %Coupon{}}

      iex> delete_coupon(coupon)
      {:error, %Ecto.Changeset{}}

  """
  def delete_coupon(%Coupon{} = coupon) do
    Repo.delete(coupon)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking coupon changes.

  ## Examples

      iex> change_coupon(coupon)
      %Ecto.Changeset{data: %Coupon{}}

  """
  def change_coupon(%Coupon{} = coupon, attrs \\ %{}) do
    Coupon.changeset(coupon, attrs)
  end

  @doc """
  Lets a user buy a coupon with fitcoins.
  """
  @spec buy_coupon(User.t()) :: {:ok, Coupon.t()} | {:error, :not_enough_fitcoins}
  def buy_coupon(user) do
    Repo.transaction(fn ->
      user = Accounts.get_user!(user.id)

      if user.fitcoins < 100 do
        Repo.rollback(:not_enough_fitcoins)
      else
        {:ok, _user} = Accounts.update_user(user, %{fitcoins: user.fitcoins - 100})

        {:ok, coupon} =
          Anoma.Garapon.create_coupon(%{
            owner_id: user.id,
            used: false
          })

        coupon
      end
    end)
  end

  @doc """
  Lets a user buy multiple coupons with fitcoins.
  """
  @spec buy_coupons(User.t(), non_neg_integer()) ::
          {:ok, [Coupon.t()]} | {:error, :not_enough_fitcoins}
  def buy_coupons(user, amount) do
    total_cost = amount * 100

    Repo.transaction(fn ->
      user = Accounts.get_user!(user.id)

      if user.fitcoins < total_cost do
        Repo.rollback(:not_enough_fitcoins)
      else
        {:ok, _user} = Accounts.update_user(user, %{fitcoins: user.fitcoins - total_cost})

        for _ <- 1..amount do
          {:ok, coupon} =
            Anoma.Garapon.create_coupon(%{
              owner_id: user.id,
              used: false
            })

          coupon
        end
      end
    end)
  end
end
