defmodule AnomaWeb.Api.UserController.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule MetaMaskAuthRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Metamask Login Request",
      type: :object,
      properties: %{
        address: %Schema{type: :string, description: "Ethereum Address", example: "0xDEADBEEF"},
        message: %Schema{
          type: :string,
          description: "Message that was signed",
          example: "Beepboop"
        },
        signature: %Schema{
          type: :string,
          description: "Signature of the message",
          example: "1234ABDCDEF"
        }
      }
    })
  end

  defmodule AuthResponse do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Authentication Response",
      type: :object,
      properties: %{
        user: Anoma.Accounts.User,
        jwt: %Schema{type: :string, description: "JWT to communicate with this API"}
      }
    })
  end

  defmodule XAuthRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "X Login Request",
      type: :object,
      properties: %{
        code: %Schema{type: :string, description: "Code", example: "supersecret"},
        code_verifier: %Schema{
          type: :string,
          description: "Code Verifier",
          example: "itsreallysecret"
        }
      }
    })
  end
end
