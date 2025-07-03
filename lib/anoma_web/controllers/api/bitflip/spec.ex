defmodule AnomaWeb.Api.BitflipController.Schemas do
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
        up: %Schema{type: :boolean, description: "Will bitcoin go up?"},
        leverage: %Schema{type: :integer, description: "Leverage multiplier", example: 1},
        points: %Schema{type: :integer, description: "Points to bet", example: 123}
      }
    })
  end

  defmodule BetDetailsRequest do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{type: :string, description: "Bet ID", example: "1234-5678-9101-1121"})
  end

  defmodule BetList do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{bets: %Schema{type: :array, items: Anoma.Bitflip.Bet}}
    })
  end
end
