defmodule AnomaWeb.Api.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule Success do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Successful",
      type: :object,
      properties: %{},
      example: %{success: true}
    })
  end

  defmodule Error do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Generic Error",
      type: :object,
      properties: %{
        error: %Schema{type: :string, description: "error message", example: "unauthorized"}
      }
    })
  end
end
