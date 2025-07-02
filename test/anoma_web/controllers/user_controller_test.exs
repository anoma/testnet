defmodule AnomaWeb.UserControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  alias Anoma.Accounts
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "test auth with invalid credentials", %{conn: conn} do
    # try and add an ethereum address to the user
    conn =
      post(conn, ~p"/api/v1/user/auth", %{code: "foobar", code_verifier: "barbar"})

    assert %{"error" => "code_exchange_failed"} = json_response(conn, 500)
    # assert %{"success" => true} = json_response(conn, 200)

    # # check that the user's ethereum address was updated
    # user = Accounts.get_user!(user.id)
    # assert user.eth_address == "0x1234567890abcdef1234567890abcdef12345678"
  end

  test "add an ethereum address to a user", %{conn: conn} do
    user = user_fixture()

    # create a jwt for this user and add it as a header
    jwt = AuthPlug.generate_jwt_token(user)
    conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

    # try and add an ethereum address to the user
    conn =
      post(conn, ~p"/api/v1/user/ethereum-address", %{
        address: "0x1234567890abcdef1234567890abcdef12345678"
      })

    assert %{} = json_response(conn, 200)

    # check that the user's ethereum address was updated
    user = Accounts.get_user!(user.id)
    assert user.eth_address == "0x1234567890abcdef1234567890abcdef12345678"
  end

  test "add an ethereum address to a user that is already in use by another user", %{conn: conn} do
    _user = user_fixture(%{eth_address: "0x1234567890abcdef1234567890abcdef12345678"})
    user = user_fixture()

    # create a jwt for this user and add it as a header
    jwt = AuthPlug.generate_jwt_token(user)
    conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

    # try and add an ethereum address to the user

    conn =
      post(conn, ~p"/api/v1/user/ethereum-address", %{
        address: "0x1234567890abcdef1234567890abcdef12345678"
      })

    assert %{"errors" => %{"eth_address" => ["has already been taken"]}} ==
             json_response(conn, 422)
  end
end
