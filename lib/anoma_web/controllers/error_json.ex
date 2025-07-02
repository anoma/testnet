defmodule AnomaWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """
  def render("400.json", _assigns) do
    %{error: "bad request"}
  end

  def render("401.json", %{error: error}) do
    %{error: error}
  end

  def render("404.json", _) do
    %{error: "not found"}
  end

  def render("422.json", %{error: error}) do
    %{error: error}
  end

  def render("500.json", %{error: error}) do
    %{error: error}
  end

  def render(template, _assigns) do
    %{
      error: Phoenix.Controller.status_message_from_template(template)
    }
  end
end
