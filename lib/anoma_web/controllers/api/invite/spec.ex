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
      properties: %{
        invite_code: %Schema{type: :string, description: "Invite code", example: "LETMEIN"}
      }
    })
  end

  defmodule InviteList do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{invites: %Schema{type: :array, items: Anoma.Invites.Invite}}
    })
  end

  defmodule InviteTree do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{
        user_id: %Schema{type: :string, example: "1234"},
        tree: %Schema{type: :array, items: InviteTree}
      },
      example: %{
        "user_id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
        "tree" => [
          %{
            "user_id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
            "tree" => [
              %{
                "user_id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
                "tree" => []
              }
            ]
          },
          %{
            "user_id" => "18d3bb76-2e27-4cd0-9912-b8b259bd3950",
            "tree" => []
          }
        ]
      }
    })
  end
end
