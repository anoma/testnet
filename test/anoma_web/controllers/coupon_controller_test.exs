defmodule AnomaWeb.Api.CouponControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  import Anoma.Accounts.CouponsFixtures
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "list/2" do
    test "lists the coupons for a user", %{conn: conn} do
      user = user_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = get(conn, ~p"/api/v1/coupons")

      assert %{"coupons" => []} = json_response(conn, 200)
    end

    test "lists the coupons for a user when multiple coupons exist", %{conn: conn} do
      user = user_fixture()
      coupon = coupon_fixture(%{owner_id: user.id})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = get(conn, ~p"/api/v1/coupons")

      assert %{"coupons" => [%{"id" => coupon.id, "used" => false}]} == json_response(conn, 200)
    end

    test "use a coupon works", %{conn: conn} do
      user = user_fixture()
      coupon = coupon_fixture(%{owner_id: user.id})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = put(conn, ~p"/api/v1/coupons/use/#{coupon.id}")

      assert %{"success" => true} == json_response(conn, 200)
    end

    test "use a coupon does not work for another users coupon", %{conn: conn} do
      user = user_fixture()
      other = user_fixture()
      coupon = coupon_fixture(%{owner_id: user.id})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(other)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = put(conn, ~p"/api/v1/coupons/use/#{coupon.id}")

      assert %{"success" => false, "error" => "invalid coupon"} == json_response(conn, 401)
    end
  end
end
