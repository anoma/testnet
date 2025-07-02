defmodule Anoma.RateLimit do
  @moduledoc """
  Rate limiter module for Anoma.
  """
  use Hammer, backend: :ets
end
