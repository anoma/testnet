defmodule AnomaWeb.Api.ExplorerControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  alias Anoma.Accounts
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "list/2" do
    test "returns empty list when user has no daily points", %{conn: conn} do
      user = user_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/explorer/")

      assert json_response(conn, 200) == %{"daily_points" => []}
    end

    test "returns user's daily points", %{conn: conn} do
      user = user_fixture()
      daily_point1 = daily_point_fixture(%{user: user, day: ~D[2023-01-01]})
      daily_point2 = daily_point_fixture(%{user: user, day: ~D[2023-01-02], claimed: true})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/explorer/")

      assert %{"daily_points" => daily_points} = json_response(conn, 200)
      assert length(daily_points) == 2

      # Should be ordered by day descending
      assert List.first(daily_points)["day"] == "2023-01-02"
      assert List.last(daily_points)["day"] == "2023-01-01"
    end

    test "only returns daily points for the current user", %{conn: conn} do
      user1 = user_fixture()
      user2 = user_fixture(email: "user2@example.com")

      daily_point_fixture(%{user: user1})
      daily_point_fixture(%{user: user2})

      conn = conn |> assign(:current_user, user1)

      conn = get(conn, ~p"/api/v1/explorer/")

      assert %{"daily_points" => daily_points} = json_response(conn, 200)
      assert length(daily_points) == 1
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/explorer/")

      assert json_response(conn, 401)
    end
  end
end
