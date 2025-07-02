defmodule AnomaWeb.Api.BetController.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule BetRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "Bet Request",
      type: :object,
      properties: %{
        up?: %Schema{type: :boolean, description: "Will bitcoin go up?"},
        leverage: %Schema{type: :integer, description: "Leverage multiplier", example: 1},
        points: %Schema{type: :integer, description: "Points to bet", example: 123}
      }
    })
  end
end
