defmodule Anoma.DailyPointsTest do
  use Anoma.DataCase

  alias Anoma.DailyPoints.DailyPoint
  alias Anoma.DailyPoints

  import Anoma.AccountsFixtures

  describe "list_daily_points/0" do
    test "returns all daily_points" do
      daily_point = daily_point_fixture()
      assert DailyPoints.list_daily_points() == [daily_point]
    end

    test "returns empty list when no daily_points exist" do
      assert DailyPoints.list_daily_points() == []
    end

    test "preloads user association" do
      user = user_fixture()
      _daily_point = daily_point_fixture(user: user)
      [result] = DailyPoints.list_daily_points()

      assert result.user.id == user.id
      assert result.user.email == user.email
    end
  end

  describe "get_daily_point!/1" do
    test "returns the daily_point with given id" do
      daily_point = daily_point_fixture()
      assert DailyPoints.get_daily_point!(daily_point.id) == daily_point
    end

    test "raises when daily_point does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        DailyPoints.get_daily_point!(Ecto.UUID.generate())
      end
    end

    test "preloads user association" do
      user = user_fixture()
      daily_point = daily_point_fixture(user: user)
      result = DailyPoints.get_daily_point!(daily_point.id)

      assert result.user.id == user.id
      assert result.user.email == user.email
    end
  end

  describe "get_daily_point/1" do
    test "returns {:ok, daily_point} when daily_point exists" do
      daily_point = daily_point_fixture()
      assert {:ok, result} = DailyPoints.get_daily_point(daily_point.id)
      assert result.id == daily_point.id
    end

    test "returns {:error, :not_found} when daily_point does not exist" do
      assert {:error, :not_found} = DailyPoints.get_daily_point(Ecto.UUID.generate())
    end

    test "preloads user association" do
      user = user_fixture()
      daily_point = daily_point_fixture(user: user)
      {:ok, result} = DailyPoints.get_daily_point(daily_point.id)

      assert result.user.id == user.id
      assert result.user.email == user.email
    end
  end

  describe "create_daily_point/1" do
    test "creates a daily_point with valid data" do
      user = user_fixture()

      valid_attrs = %{
        location: "DEADBEEF",
        day: ~D[2023-01-01],
        claimed: true,
        user_id: user.id
      }

      assert {:ok, %DailyPoint{} = daily_point} = DailyPoints.create_daily_point(valid_attrs)
      assert daily_point.location == "DEADBEEF"
      assert daily_point.day == ~D[2023-01-01]
      assert daily_point.claimed == true
      assert daily_point.user_id == user.id
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = DailyPoints.create_daily_point(%{})
    end

    test "requires location" do
      user = user_fixture()
      attrs = %{day: ~D[2023-01-01], user_id: user.id}

      assert {:error, changeset} = DailyPoints.create_daily_point(attrs)
      assert "can't be blank" in errors_on(changeset).location
    end

    test "requires day" do
      user = user_fixture()
      attrs = %{location: "DEADBEEF", user_id: user.id}

      assert {:error, changeset} = DailyPoints.create_daily_point(attrs)
      assert "can't be blank" in errors_on(changeset).day
    end

    test "requires user" do
      attrs = %{location: "DEADBEEF"}

      assert {:error, changeset} = DailyPoints.create_daily_point(attrs)
      assert "can't be blank" in errors_on(changeset).day
    end

    test "defaults claimed to false when not provided" do
      user = user_fixture()
      attrs = %{location: "DEADBEEF", day: ~D[2023-01-01], user_id: user.id}

      assert {:ok, daily_point} = DailyPoints.create_daily_point(attrs)
      assert daily_point.claimed == false
    end
  end

  describe "update_daily_point/2" do
    test "updates the daily_point with valid data" do
      daily_point = daily_point_fixture()

      update_attrs = %{
        location: "NOTSODEADBEEF",
        claimed: true
      }

      assert {:ok, %DailyPoint{} = updated_daily_point} =
               DailyPoints.update_daily_point(daily_point, update_attrs)

      assert updated_daily_point.location == "NOTSODEADBEEF"
      assert updated_daily_point.claimed == true
    end

    test "returns error changeset with invalid data" do
      daily_point = daily_point_fixture()

      assert {:error, %Ecto.Changeset{}} =
               DailyPoints.update_daily_point(daily_point, %{location: nil})

      assert daily_point == DailyPoints.get_daily_point!(daily_point.id)
    end
  end

  describe "delete_daily_point/1" do
    test "deletes the daily_point" do
      daily_point = daily_point_fixture()
      assert {:ok, %DailyPoint{}} = DailyPoints.delete_daily_point(daily_point)
      assert_raise Ecto.NoResultsError, fn -> DailyPoints.get_daily_point!(daily_point.id) end
    end
  end

  describe "change_daily_point/2" do
    test "returns a daily_point changeset" do
      daily_point = daily_point_fixture()
      assert %Ecto.Changeset{} = DailyPoints.change_daily_point(daily_point)
    end

    test "returns changeset with given attributes" do
      daily_point = daily_point_fixture()
      attrs = %{location: "New Location"}

      changeset = DailyPoints.change_daily_point(daily_point, attrs)
      assert changeset.changes.location == "New Location"
    end
  end

  describe "get_user_daily_points/1" do
    test "returns all daily points for a user ordered by date desc" do
      user = user_fixture()
      other_user = user_fixture()

      daily_point1 = daily_point_fixture(user: user, day: ~D[2023-01-01])
      daily_point2 = daily_point_fixture(user: user, day: ~D[2023-01-03])
      daily_point3 = daily_point_fixture(user: user, day: ~D[2023-01-02])
      _other_user_point = daily_point_fixture(user: other_user, day: ~D[2023-01-01])

      results = DailyPoints.get_user_daily_points(user)

      assert length(results) == 3
      assert [daily_point2, daily_point3, daily_point1] == results
    end

    test "returns empty list when user has no daily points" do
      user = user_fixture()
      assert DailyPoints.get_user_daily_points(user) == []
    end
  end

  describe "get_user_daily_points_by_date/2" do
    test "returns list of points when user has daily points for date" do
      user = user_fixture()
      date = ~D[2023-01-01]
      daily_point = daily_point_fixture(user: user, day: date)

      assert [fetched_point] = DailyPoints.get_user_daily_points_by_date(user, date)
      assert fetched_point.user_id == daily_point.user.id
      assert fetched_point.day == daily_point.day
      assert fetched_point.claimed == daily_point.claimed
    end

    test "returns {:error, :not_found} when user has no daily point for date" do
      user = user_fixture()
      date = ~D[2023-01-01]

      assert [] == DailyPoints.get_user_daily_points_by_date(user, date)
    end

    test "returns {:error, :not_found} when other user has daily point for date" do
      user = user_fixture()
      other_user = user_fixture()
      date = ~D[2023-01-01]
      _daily_point = daily_point_fixture(user: other_user, day: date)

      assert [] == DailyPoints.get_user_daily_points_by_date(user, date)
    end
  end

  describe "claim_daily_point/3" do
    test "creates new daily point when user has no existing points for date" do
      user = user_fixture()
      daily_point = daily_point_fixture(%{user: user})

      assert {:ok, updated_daily_point} = DailyPoints.claim_daily_point(daily_point)
      assert updated_daily_point.user_id == user.id
      assert updated_daily_point.day == daily_point.day
      assert updated_daily_point.location == daily_point.location
      assert updated_daily_point.claimed == true
    end

    test "updates existing unclaimed daily point to claimed" do
      user = user_fixture()
      daily_point = daily_point_fixture(user: user)

      assert {:ok, updated_daily_point} = DailyPoints.claim_daily_point(daily_point)
      assert updated_daily_point.id == daily_point.id
      assert updated_daily_point.claimed == true
      assert updated_daily_point.location == daily_point.location
    end

    test "returns error when trying to claim already claimed daily point" do
      user = user_fixture()
      daily_point = daily_point_fixture(user: user, claimed: true)

      assert {:error, :already_claimed} = DailyPoints.claim_daily_point(daily_point)
    end
  end
end
