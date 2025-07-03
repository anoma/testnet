defmodule AnomaWeb.Api.UserController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Accounts
  alias Anoma.Ethereum
  alias AnomaWeb.Api
  alias AnomaWeb.Api.UserController.Schemas
  alias AnomaWeb.Plugs.AuthPlug
  alias AnomaWeb.Twitter

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
    security: [%{"authorization" => []}],
    summary: "Returns the user profile",
    responses: %{
      200 => {"success", "application/json", Accounts.User},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  operation :x_auth,
    security: [%{"authorization" => []}],
    summary: "Submit X authentication codes ",
    request_body: {"MetaMask auth parameters", "application/json", Schemas.XAuthRequest},
    responses: %{
      200 => {"success", "application/json", Api.Schemas.Success},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  @doc """
  The front-end calls this endpoint to let the backend obtain an access token
  for its profile.
  """
  @spec x_auth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def x_auth(conn, %{"code" => code, "code_verifier" => code_verifier}) do
    user = conn.assigns.current_user

    with {:ok, access_token} <-
           Twitter.fetch_access_token(code, code_verifier),
         {:ok, user_meta_data} <- Twitter.fetch_user_meta_data(access_token) do
      # put the meta data in the user's profile
      {:ok, _} = Accounts.update_user_twitter_data(user, user_meta_data, access_token)

      # return an empty response
      json(conn, %{})
    end
  end

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
end
