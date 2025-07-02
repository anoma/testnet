defmodule AnomaWeb.Api.InviteController do
  use AnomaWeb, :controller

  alias Anoma.Accounts.Invite
  alias Anoma.Invites
  alias AnomaWeb.ApiSpec.Schemas.JsonError
  alias AnomaWeb.ApiSpec.Schemas.JsonSuccess
  alias OpenApiSpex.Operation
  alias OpenApiSpex.Schema
  alias AnomaWeb.Api.InviteController.Schemas

  action_fallback AnomaWeb.FallbackController

  use OpenApiSpex.ControllerSpecs

  tags ["Invites"]

  operation :redeem_invite,
    security: [%{"authorization" => []}],
    summary: "Redeem an invite code",
    request_body: {"Invite Redeem Request", "application/json", Schemas.RedeemRequest},
    responses: %{
      401 => Operation.response("Failure", "application/json", JsonError),
      200 => Operation.response("Failure", "application/json", JsonSuccess)
    }

  operation :list_invites,
    security: [%{"authorization" => []}],
    summary: "List invites",
    request_body: {},
    responses: %{
      200 =>
        {"success", "application/json",
         %Schema{
           type: :object,
           properties: %{
             invites: %Schema{
               type: :array,
               items: %Schema{
                 type: :object,
                 properties: %{
                   code: %Schema{type: :string, description: "invite code", example: "INVITEXYZ"},
                   claimed?: %Schema{
                     type: :bool,
                     description: "invite claimed or not",
                     example: false
                   }
                 }
               }
             }
           }
         }},
      400 => {"Failed to authenticate", "application/json", JsonError}
    }

  @doc """
  Lets a user claim an invite code
  """
  def redeem_invite(conn, %{"invite_code" => invite_code}) do
    with user when not is_nil(user) <- Map.get(conn.assigns, :current_user),
         invite when not is_nil(invite) <- Invites.get_invite_by_code!(invite_code),
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
