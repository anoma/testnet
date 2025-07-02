defmodule AnomaWeb.Plugs.LocalOnly do
  @moduledoc """
  Plug for authenticating users via JWT tokens.

  This plug verifies the JWT token sent in the Authorization header
  and loads the current user into the connection assigns.
  """

  import Plug.Conn

  require Logger

  def init(opts), do: opts

  def call(conn, opts) do
    path = Keyword.get(opts, :path)

    case {conn.request_path, conn.remote_ip} do
      {^path, {127, 0, 0, 1}} ->
        conn

      {^path, _} ->
        conn
        |> put_status(:unauthorized)
        |> resp(404, "not found")
        |> halt()

      _ ->
        conn
    end
  end
end
