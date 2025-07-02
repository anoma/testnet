defmodule AnomaWeb.Plugs.AuthPlug do
  @moduledoc """
  Plug for authenticating users via JWT tokens.

  This plug verifies the JWT token sent in the Authorization header
  and loads the current user into the connection assigns.
  """

  import Plug.Conn
  alias Anoma.Accounts
  alias Anoma.Accounts.User

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    if Application.get_env(:anoma, :debug_auth) do
      conn
      |> assign(:invited?, true)
      |> assign(:current_user, Accounts.list_users() |> Enum.sort_by(& &1.id) |> hd())
    else
      case get_token_from_header(conn) do
        {:ok, token} ->
          Logger.debug("auth token: #{token}")

          case verify_token(token) do
            {:ok, payload} ->
              case load_user(payload) do
                {:ok, user} ->
                  invited? = user.invite != nil

                  conn
                  |> assign(:invited?, invited?)
                  |> assign(:current_user, user)

                {:error, _} ->
                  unauthorized(conn)
              end

            {:error, _} ->
              unauthorized(conn)
          end

        {:error, _} ->
          unauthorized(conn)
      end
    end
  end

  defp get_token_from_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, "No valid authorization header"}
    end
  end

  @doc """
  Generate a JWT for the front-end to authenticate with this backend.
  """
  @spec generate_jwt_token(User.t()) :: binary()
  def generate_jwt_token(user) do
    payload = %{
      "user_id" => user.id,
      "exp" => DateTime.utc_now() |> DateTime.add(24 * 60 * 60, :second) |> DateTime.to_unix(),
      "iat" => DateTime.utc_now() |> DateTime.to_unix(),
      "iss" => "anoma_backend"
    }

    Phoenix.Token.sign(AnomaWeb.Endpoint, "user_auth", payload, max_age: 24 * 60 * 60)
  end

  @spec verify_token(binary()) :: {:ok, map()} | {:error, atom()}
  def verify_token(token) do
    case Phoenix.Token.verify(AnomaWeb.Endpoint, "user_auth", token, max_age: 24 * 60 * 60) do
      {:ok, payload} -> {:ok, payload}
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_user(payload) do
    case payload["user_id"] do
      user_id when is_binary(user_id) ->
        try do
          user = Accounts.get_user!(user_id) |> Anoma.Repo.preload(:invite)
          {:ok, user}
        rescue
          Ecto.NoResultsError -> {:error, "User not found"}
        end

      _ ->
        {:error, "Invalid payload"}
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: "Unauthorized"})
    |> halt()
  end
end
