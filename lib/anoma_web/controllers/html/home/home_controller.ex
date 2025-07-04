defmodule AnomaWeb.Html.HomeController do
  use AnomaWeb, :controller

  action_fallback AnomaWeb.FallbackController

  def index(conn, _params) do
    render(conn, :home, layout: false)
    # conn
    # |> fetch_session()
    # |> put_session(:user_id, 1)
    # |> redirect(to: "/index.html")
  end
end
