defmodule AnomaWeb.UserControllerTest do
  use AnomaWeb.ConnCase

  import Anoma.AccountsFixtures
  alias Anoma.Accounts
  alias AnomaWeb.Plugs.AuthPlug

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "POST /api/v1/user/metamask-auth" do
    # Note: These tests focus on the controller logic. The Ethereum signature verification
    # would typically be mocked or tested separately in the Ethereum module tests.
    # The controller uses pattern matching which expects all three parameters to be present.

    test "returns error when required parameters are missing", %{conn: conn} do
      # Missing signature - pattern match should fail and return 400
      assert_error_sent 400, fn ->
        conn =
          post(conn, ~p"/api/v1/user/metamask-auth", %{
            "address" => "0x1234567890123456789012345678901234567890",
            "message" => "test message"
          })

        assert %{} == json_response(conn, 400)
      end

      # Missing address - pattern match should fail and return 400
      assert_error_sent 400, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "message" => "test message",
          "signature" => "0xsignature"
        })
      end

      # Missing message - pattern match should fail and return 400
      assert_error_sent 400, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "address" => "0x1234567890123456789012345678901234567890",
          "signature" => "0xsignature"
        })
      end
    end

    test "returns error with empty request body", %{conn: conn} do
      # Empty body should fail pattern matching
      assert_error_sent 400, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{})
      end
    end

    test "returns error with malformed signature format", %{conn: conn} do
      eth_address = "0x" <> Base.encode16(:crypto.strong_rand_bytes(20), case: :lower)

      # This will cause an ArgumentError in Ethereum.verify due to invalid hex characters
      assert_error_sent 500, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "address" => eth_address,
          "message" => "test message",
          "signature" => "not_a_valid_signature_format"
        })
      end
    end

    test "returns error with invalid hex signature", %{conn: conn} do
      eth_address = "0x" <> Base.encode16(:crypto.strong_rand_bytes(20), case: :lower)

      # This will cause an ArgumentError due to wrong hex length
      assert_error_sent 500, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "address" => eth_address,
          "message" => "test message",
          "signature" => "0xnotvalidhex"
        })
      end
    end

    test "returns error with wrong signature length", %{conn: conn} do
      eth_address = "0x" <> Base.encode16(:crypto.strong_rand_bytes(20), case: :lower)

      # This will cause an ArgumentError during binary conversion
      assert_error_sent 500, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "address" => eth_address,
          "message" => "test message",
          # Too short
          "signature" => "0x123456"
        })
      end
    end

    test "handles request with null address", %{conn: conn} do
      # Null address will cause String.downcase to fail
      assert_error_sent 500, fn ->
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "address" => nil,
          "message" => "test message",
          "signature" => "0x" <> Base.encode16(:crypto.strong_rand_bytes(65), case: :lower)
        })
      end
    end

    test "returns error response for signature verification failure", %{conn: conn} do
      # Use a valid format but invalid signature that will fail verification
      conn =
        post(conn, ~p"/api/v1/user/metamask-auth", %{
          "address" => "0x" <> Base.encode16(:crypto.strong_rand_bytes(20), case: :lower),
          "message" => "test message",
          "signature" => "0x" <> Base.encode16(:crypto.strong_rand_bytes(65), case: :lower)
        })

      # Should get 500 status with specific error message for verification failure
      response = json_response(conn, 500)
      assert response["error"] == "could_not_verify_signature"
    end
  end

  describe "GET /api/v1/user/ (profile)" do
    test "returns user profile when authenticated", %{conn: conn} do
      user =
        user_fixture(%{
          points: 100,
          fitcoins: 50,
          eth_address: "0x" <> Base.encode16(:crypto.strong_rand_bytes(20), case: :lower)
        })

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/user/")

      response = json_response(conn, 200)
      assert response["id"] == user.id
      assert response["points"] == 100
      assert response["fitcoins"] == 50
      assert response["eth_address"] == user.eth_address
    end

    test "returns fresh user data from database", %{conn: conn} do
      user = user_fixture(%{points: 0})

      # Update user points directly in database
      {:ok, updated_user} = Accounts.add_points_to_user(user, 250)

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/user/")

      response = json_response(conn, 200)
      assert response["points"] == 250
      assert response["id"] == updated_user.id
    end

    test "returns unauthorized when no token provided", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/user/")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end

    test "returns unauthorized when invalid token provided", %{conn: conn} do
      conn = put_req_header(conn, "authorization", "Bearer invalid_token")
      conn = get(conn, ~p"/api/v1/user/")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end

    test "returns unauthorized when token is malformed", %{conn: conn} do
      # Test with clearly invalid token format
      expired_token = "clearly.invalid.jwt.token.format"

      conn = put_req_header(conn, "authorization", "Bearer #{expired_token}")
      conn = get(conn, ~p"/api/v1/user/")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end

    test "returns unauthorized when user no longer exists", %{conn: conn} do
      user = user_fixture()
      jwt = AuthPlug.generate_jwt_token(user)

      # Delete the user
      Anoma.Repo.delete!(user)

      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")
      conn = get(conn, ~p"/api/v1/user/")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end

    test "returns user with preloaded associations", %{conn: conn} do
      # Create user with invite
      user = user_fixture()
      invite = invite_fixture()
      Anoma.Invites.claim_invite(invite, user)

      jwt = AuthPlug.generate_jwt_token(user)
      conn = put_req_header(conn, "authorization", "Bearer #{jwt}")

      conn = get(conn, ~p"/api/v1/user/")

      # Should not raise any errors and return user data
      assert json_response(conn, 200)["id"] == user.id
    end

    test "handles malformed authorization header", %{conn: conn} do
      # Missing "Bearer " prefix
      conn = put_req_header(conn, "authorization", "malformed_token")
      conn = get(conn, ~p"/api/v1/user/")
      assert json_response(conn, 401)["error"] == "Unauthorized"

      # Empty authorization header
      conn = build_conn()
      conn = put_req_header(conn, "accept", "application/json")
      conn = put_req_header(conn, "authorization", "")
      conn = get(conn, ~p"/api/v1/user/")
      assert json_response(conn, 401)["error"] == "Unauthorized"
    end
  end
end
