defmodule AnomaWeb.Api.FitcoinControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  alias Anoma.Accounts
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "add/2" do
    test "successfully adds 1 fitcoin to user's balance", %{conn: conn} do
      user = user_fixture(%{fitcoins: 5})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = post(conn, ~p"/api/v1/fitcoin")

      assert %{"fitcoins" => 6} = json_response(conn, 200)

      # verify the user's fitcoin balance was updated in the database
      updated_user = Accounts.get_user!(user.id)
      assert updated_user.fitcoins == 6
    end

    test "adds fitcoin to user with nil fitcoins", %{conn: conn} do
      user = user_fixture(%{fitcoins: nil})

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = post(conn, ~p"/api/v1/fitcoin")

      assert %{"fitcoins" => 1} = json_response(conn, 200)

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.fitcoins == 1
    end

    test "adds fitcoin to user with zero fitcoins", %{conn: conn} do
      user = user_fixture(%{fitcoins: 0})

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = post(conn, ~p"/api/v1/fitcoin")

      assert %{"fitcoins" => 1} = json_response(conn, 200)

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.fitcoins == 1
    end

    test "returns 401 when user is not authenticated", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/fitcoin")

      assert json_response(conn, 401)
    end

    test "returns 401 with invalid JWT token", %{conn: conn} do
      conn = put_req_header(conn, "authorization", "Bearer invalid_token")

      conn = post(conn, ~p"/api/v1/fitcoin")

      assert json_response(conn, 401)
    end
  end

  describe "balance/2" do
    test "returns user's current fitcoin balance", %{conn: conn} do
      user = user_fixture(%{fitcoins: 10})

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/fitcoin/balance")

      assert %{"fitcoins" => 10} = json_response(conn, 200)
    end

    test "returns zero balance for user with nil fitcoins", %{conn: conn} do
      user = user_fixture(%{fitcoins: nil})

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/fitcoin/balance")

      assert %{"fitcoins" => 0} = json_response(conn, 200)
    end

    test "returns zero balance for user with zero fitcoins", %{conn: conn} do
      user = user_fixture(%{fitcoins: 0})

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/fitcoin/balance")

      assert %{"fitcoins" => 0} = json_response(conn, 200)
    end

    test "returns 401 when user is not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/fitcoin/balance")

      assert json_response(conn, 401)
    end

    test "returns 401 with invalid JWT token", %{conn: conn} do
      conn = put_req_header(conn, "authorization", "Bearer invalid_token")

      conn = get(conn, ~p"/api/v1/fitcoin/balance")

      assert json_response(conn, 401)
    end
  end
end
