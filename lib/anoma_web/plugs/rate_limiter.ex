defmodule AnomaWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting an action.
  """

  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, opts) do
    user_id = conn.assigns.current_user.id
    key = "fitcoin:#{user_id}"
    scale = :timer.seconds(1)
    limit = 10

    if Phoenix.Controller.action_name(conn) == Keyword.get(opts, :action, nil) do
      case Anoma.RateLimit.hit(key, scale, limit) do
        {:allow, _count} ->
          conn

        {:deny, retry_after} ->
          conn
          |> put_resp_header("retry-after", Integer.to_string(div(retry_after, 1000)))
          |> send_resp(429, [])
          |> halt()
      end
    else
      conn
    end
  end
end
