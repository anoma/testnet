defmodule AnomaWeb.Api.UserJSON do
  @doc """
  Renders the success update ethereum address action.
  """
  def auth(%{user: user, jwt: token}) do
    %{success: true, user: user, jwt: token}
  end

  @doc """
  Renders the user profile.
  """
  def profile(%{user: user}) do
    user
  end
end
