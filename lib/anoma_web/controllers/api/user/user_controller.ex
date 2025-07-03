defmodule AnomaWeb.Api.UserController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Accounts
  alias Anoma.Ethereum
  alias AnomaWeb.Api
  alias AnomaWeb.Api.UserController.Schemas
  alias AnomaWeb.Plugs.AuthPlug

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  tags ["Users"]

  operation :metamask_auth,
    summary: "Authenticate with MetaMask signature",
    request_body: {"MetaMask auth parameters", "application/json", Schemas.MetaMaskAuthRequest},
    responses: %{
      200 => {"success", "application/json", Schemas.AuthResponse},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :profile,
    summary: "Returns the user profile",
    responses: %{
      200 => {"success", "application/json", Accounts.User},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  @doc """
  Authenticate a user with MetaMask signature verification.
  """
  @spec metamask_auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def metamask_auth(conn, %{"address" => address, "message" => message, "signature" => signature}) do
    with true <- Ethereum.verify(message, signature, address),
         {:ok, db_user} <- Accounts.create_or_update_user_with_eth_address(address),
         token <- AuthPlug.generate_jwt_token(db_user) do
      db_user = Anoma.Repo.preload(db_user, [:invite, :invites, :daily_points])
      render(conn, :auth, user: db_user, jwt: token)
    else
      false ->
        {:error, :could_not_verify_signature}

      e ->
        e
    end
  end

  @doc """
  Returns the profile for the logged in user.
  """
  @spec profile(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def profile(conn, %{}) do
    user = conn.assigns.current_user
    render(conn, :profile, user: Accounts.get_user!(user.id))
  end

  def invite_tree(conn, %{}) do
    _user = conn.assigns.current_user
  end
end
