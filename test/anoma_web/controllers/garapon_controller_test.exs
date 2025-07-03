defmodule AnomaWeb.Api.CouponControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  import Anoma.GaraponFixtures
  alias Anoma.Accounts
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "buy" do
    test "enough fitcoins", %{conn: conn} do
      user = user_fixture(%{fitcoins: 100})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = post(conn, ~p"/api/v1/garapon/buy", %{amount: 1})

      assert %{
               "coupons" => [
                 %{
                   "id" => _,
                   "prize" => nil,
                   "prize_amount" => nil,
                   "used" => false
                 }
               ]
             } = json_response(conn, 200)

      user = Accounts.get_user!(user.id)
      assert user.fitcoins == 0
    end
  end

  describe "list/2" do
    test "lists the coupons for a user", %{conn: conn} do
      user = user_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = get(conn, ~p"/api/v1/garapon")

      assert %{"coupons" => []} = json_response(conn, 200)
    end

    test "lists the coupons for a user when multiple coupons exist", %{conn: conn} do
      user = user_fixture()
      coupon = coupon_fixture(%{owner_id: user.id})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = get(conn, ~p"/api/v1/garapon")

      assert %{
               "coupons" => [
                 %{"id" => coupon.id, "used" => false, "prize" => nil, "prize_amount" => nil}
               ]
             } == json_response(conn, 200)
    end

    test "use a coupon works", %{conn: conn} do
      user = user_fixture()
      coupon = coupon_fixture(%{owner_id: user.id})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = put(conn, ~p"/api/v1/garapon/use/", %{id: coupon.id})

      assert %{"id" => _, "prize" => _, "prize_amount" => _, "used" => true} =
               json_response(conn, 200)
    end

    test "use a coupon does not work for another users coupon", %{conn: conn} do
      user = user_fixture()
      other = user_fixture()
      coupon = coupon_fixture(%{owner_id: user.id})

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(other)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # list the coupons, except empty
      conn = put(conn, ~p"/api/v1/garapon/use/", %{id: coupon.id})

      assert %{"error" => "invalid coupon"} == json_response(conn, 401)
    end
  end
end
