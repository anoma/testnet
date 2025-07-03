defmodule AnomaWeb.Api.ExplorerController.Schemas do
  @moduledoc """
  Specifications of common return values from the api.
  """
  alias OpenApiSpex.Schema

  defmodule DailyPointsList do
    @moduledoc false
    require OpenApiSpex

    OpenApiSpex.schema(%{
      type: :object,
      properties: %{daily_points: %Schema{type: :array, items: Anoma.DailyPoints.DailyPoint}}
    })
  end
end
