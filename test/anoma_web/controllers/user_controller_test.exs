defmodule AnomaWeb.UserControllerTest do
  use AnomaWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end
end
