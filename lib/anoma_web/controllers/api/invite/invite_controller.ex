defmodule AnomaWeb.Api.InviteController do
  use AnomaWeb, :controller

  alias Anoma.Accounts.Invite
  alias Anoma.Invites
  alias AnomaWeb.Api
  alias AnomaWeb.Api.InviteController.Schemas

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  # ----------------------------------------------------------------------------
  # OpenAPI Spec

  tags ["Invites"]

  operation :redeem_invite,
    security: [%{"authorization" => []}],
    summary: "Redeem an invite code",
    request_body: {"Invite Redeem Request", "application/json", Schemas.RedeemRequest},
    responses: %{
      400 => {"Generic error", "application/json", Api.Schemas.Error},
      200 => {"Invite redeemed", "application/json", Api.Schemas.Success}
    }

  operation :list_invites,
    security: [%{"authorization" => []}],
    summary: "List invites",
    responses: %{
      200 => {"List of invites", "application/json", Schemas.InviteList},
      400 => {"Generic error", "application/json", Api.Schemas.Error}
    }

  # ----------------------------------------------------------------------------
  # Actions

  @doc """
  Lets a user claim an invite code
  """
  def redeem_invite(conn, %{"invite_code" => invite_code}) do
    user =
      conn.assigns.current_user
      |> Anoma.Repo.preload(:invite)

    with {:ok, invite} <- Invites.get_invite_by_code(invite_code),
         {:ok, %Invite{}} <- Invites.claim_invite(invite, user) do
      render(conn, :redeem_invite)
    end
  end

  @doc """
  Returns a list of all the invites the user can send out.
  """
  def list_invites(conn, _params) do
    with user when not is_nil(user) <- Map.get(conn.assigns, :current_user),
         invites <- Invites.invites_for(user) do
      render(conn, :list_invites, invites: invites)
    end
  end
end
