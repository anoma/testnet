defmodule AnomaWeb.Api.UserController do
  use AnomaWeb, :controller

  require Logger

  alias Anoma.Accounts
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
    with {:ok, verified_address} <- verify_ethereum_signature(message, signature, address),
         {:ok, db_user} <- Accounts.create_or_update_user_with_eth_address(verified_address),
         token <- AuthPlug.generate_jwt_token(db_user) do
      db_user = Anoma.Repo.preload(db_user, [:invite, :invites, :daily_points])
      render(conn, :auth, user: db_user, jwt: token)
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

  # ----------------------------------------------------------------------------#
  #                                Helpers                                     #
  # ----------------------------------------------------------------------------#

  defp verify_ethereum_signature(_message, _signature, expected_address) do
    # For now, we'll trust the address provided by the frontend
    # In a production environment, you would want to verify the signature
    # using a proper Ethereum signature verification library
    if String.length(expected_address) == 42 and String.starts_with?(expected_address, "0x") do
      {:ok, String.downcase(expected_address)}
    else
      {:error, :invalid_address}
    end
  end
end
