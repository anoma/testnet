defmodule Anoma.GaraponTest do
  use Anoma.DataCase

  alias Anoma.Garapon.Coupon
  alias Anoma.Garapon

  import Anoma.GaraponFixtures
  import Anoma.AccountsFixtures

  describe "coupons" do
    @invalid_attrs %{}

    test "list_coupons/0 returns all coupons" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})
      assert Garapon.list_coupons() == [coupon]
    end

    test "get_coupon!/1 returns the coupon with given id" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})
      assert Garapon.get_coupon!(coupon.id) == coupon
    end

    test "create_coupon/1 with valid data creates a coupon" do
      owner = user_fixture()
      valid_attrs = %{owner_id: owner.id}

      assert {:ok, %Coupon{} = _coupon} = Garapon.create_coupon(valid_attrs)
    end

    test "create_coupon/1 with valid data creates a coupon that is not used" do
      owner = user_fixture()
      valid_attrs = %{owner_id: owner.id}

      assert {:ok, %Coupon{} = coupon} = Garapon.create_coupon(valid_attrs)
      refute coupon.used
    end

    test "create_coupon/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Garapon.create_coupon(@invalid_attrs)
    end

    test "update_coupon/2 with valid data updates the coupon" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})
      update_attrs = %{}

      assert {:ok, %Coupon{} = _coupon} = Garapon.update_coupon(coupon, update_attrs)
    end

    test "update_coupon/2 with invalid data returns error changeset" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})
      assert {:error, %Ecto.Changeset{}} = Garapon.update_coupon(coupon, %{owner_id: nil})
      assert coupon == Garapon.get_coupon!(coupon.id)
    end

    test "delete_coupon/1 deletes the coupon" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})
      assert {:ok, %Coupon{}} = Garapon.delete_coupon(coupon)
      assert_raise Ecto.NoResultsError, fn -> Garapon.get_coupon!(coupon.id) end
    end

    test "change_coupon/1 returns a coupon changeset" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})
      assert %Ecto.Changeset{} = Garapon.change_coupon(coupon)
    end

    test "use_coupon/1 marks a coupon as used" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})

      # mark the coupon as used
      {:ok, coupon} = Garapon.use_coupon(coupon)

      # verify the coupon state
      coupon = Garapon.get_coupon!(coupon.id)
      assert coupon.used
    end

    test "use_coupon/1 cannot be used on a used coupon" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})

      # mark the coupon as used
      {:ok, coupon} = Garapon.use_coupon(coupon)
      {:error, :coupon_already_used} = Garapon.use_coupon(coupon)

      # verify the coupon state
      coupon = Garapon.get_coupon!(coupon.id)
      assert coupon.used
    end

    test "use_coupon/1 cannot be used on somebody elses coupon" do
      owner = user_fixture()
      coupon = coupon_fixture(%{owner_id: owner.id})

      # mark the coupon as used
      {:ok, coupon} = Garapon.use_coupon(coupon)
      {:error, :coupon_already_used} = Garapon.use_coupon(coupon)

      # verify the coupon state
      coupon = Garapon.get_coupon!(coupon.id)
      assert coupon.used
    end
  end
end
