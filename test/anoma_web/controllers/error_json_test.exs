defmodule AnomaWeb.ErrorJSONTest do
  use AnomaWeb.ConnCase, async: true

  test "renders 404" do
    assert AnomaWeb.ErrorJSON.render("404.json", %{}) == %{error: "not found"}
  end

  test "renders 500" do
    assert AnomaWeb.ErrorJSON.render("500.json", %{}) == %{
             error: "Internal Server Error"
           }
  end
end
