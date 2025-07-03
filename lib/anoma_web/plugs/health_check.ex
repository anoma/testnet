defmodule AnomaWeb.Plugs.HealthCheck do
  @moduledoc """
  Plug that provides a health check endpoint.
  """
  import Plug.Conn

  # init/1 is required by the Plug behaviour but can be left as-is.
  def init(opts), do: opts

  # If the request path matches "/health", we return a 200 response.
  def call(%Plug.Conn{request_path: "/health"} = conn, _opts) do
    conn
    |> put_resp_content_type("application/json", nil)
    |> send_resp(
      :ok,
      ~s({"commit": "#{Application.get_env(:anoma, :git_commit_sha)}", "app_version": "#{Application.spec(:anoma, :vsn)}"})
    )
    |> halt()
  end

  # If the request path is anything else, we pass the connection along.
  def call(conn, _opts), do: conn
end
