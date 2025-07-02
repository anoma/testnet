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
      properties: %{
        success: %Schema{type: :boolean, description: "success message", example: true}
      },
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
        success: %Schema{type: :boolean, description: "error state", example: false}
      },
      example: %{success: false}
    })
  end
end
