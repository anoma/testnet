defmodule AnomaWeb.Api.InviteController.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule RedeemRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Invite Request",
      type: :object,
      properties: %{invite_code: %Schema{type: :string, description: "Invite code", example: "LETMEIN"}}
    })
  end

  defmodule InviteList do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{invites: %Schema{type: :array, items: Anoma.Accounts.Invite}}
    })
  end
end
