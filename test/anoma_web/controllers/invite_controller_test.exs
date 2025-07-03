defmodule AnomaWeb.InviteControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  alias Anoma.Accounts
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "list invites" do
    test "renders empty invites", %{conn: conn} do
      user = user_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = get(conn, ~p"/api/v1/invite")
      assert %{"invites" => []} = json_response(conn, 200)
    end

    test "renders invites", %{conn: conn} do
      user = user_fixture()
      invite = invite_fixture()
      Anoma.Invites.assign_invite(invite, user)
      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = get(conn, ~p"/api/v1/invite")

      assert %{
               "invites" => [
                 %{
                   "code" => "some code",
                   "id" => _,
                   "invitee_id" => nil
                 }
               ]
             } =
               json_response(conn, 200)
    end

    test "renders invites that are claimed too", %{conn: conn} do
      user = user_fixture()
      invitee = user_fixture()
      invite = invite_fixture()
      Anoma.Invites.assign_invite(invite, user)
      Anoma.Invites.claim_invite(invite, invitee)

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = get(conn, ~p"/api/v1/invite")

      assert %{
               "invites" => [
                 %{
                   "code" => "some code",
                   "id" => _,
                   "invitee_id" => _
                 }
               ]
             } =
               json_response(conn, 200)
    end
  end

  describe "buy invite" do
    test "user has enogh gas", %{conn: conn} do
      user = user_fixture(%{gas: 100})
      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = post(conn, ~p"/api/v1/invite/buy")

      assert %{
               "code" => _,
               "id" => _,
               "invitee_id" => _
             } = json_response(conn, 200)

      # assert the user has an invite that is unclaimed
      user = Accounts.get_user!(user.id) |> Anoma.Repo.preload(:invites)
      assert Enum.count(user.invites) == 1
    end

    test "user doesnt have enough gas", %{conn: conn} do
      user = user_fixture(%{gas: 0})
      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = post(conn, ~p"/api/v1/invite/buy")

      assert %{"error" => "not_enough_gas"} = json_response(conn, 401)

      # assert the user has an invite that is unclaimed
      user = Accounts.get_user!(user.id) |> Anoma.Repo.preload(:invites)
      assert Enum.empty?(user.invites)
    end
  end

  describe "claim invite" do
    test "renders invite when invite is valid", %{conn: conn} do
      user = user_fixture()
      invite = invite_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = put(conn, ~p"/api/v1/invite/redeem/", %{invite_code: invite.code})
      assert %{} = json_response(conn, 200)
    end

    test "renders invite when invite is invalid", %{conn: conn} do
      user = user_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      conn = put(conn, ~p"/api/v1/invite/redeem/", %{invite_code: "invalid"})
      assert conn.status == 404
    end

    test "error when not logged in", %{conn: conn} do
      invite = invite_fixture()

      # try and claim an invite
      conn = put(conn, ~p"/api/v1/invite/redeem/", %{invite_code: invite.code})
      assert "Unauthorized" = json_response(conn, 401)["error"]
    end

    test "error payload invalid", %{conn: conn} do
      user = user_fixture()

      # create a jwt for this user and add it as a header
      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      # try and claim an invite
      # try and claim an invite
      assert_error_sent 400, fn ->
        conn = put(conn, ~p"/api/v1/invite/redeem/", %{some_key: "some value"})
        assert "Unauthorized" = json_response(conn, 401)["error"]
      end
    end
  end
end
