defmodule AnomaWeb.Twitter do
  @moduledoc """
  This module contains functions to communicate with the Twitter API.
  Used to turn `code` and `code_verified` into an accesstoken for the user.
  """
  require Logger

  @twitter_api_url "https://api.twitter.com/2/oauth2/token"
  @twitter_user_meta_data_url "https://api.twitter.com/2/users/me?user.fields=id,name,username,profile_image_url,description,public_metrics,verified"

  @doc """
  Given the code and code verifier from the user, exchange them for an access
  token.
  """
  @spec fetch_access_token(String.t(), String.t()) ::
          {:ok, String.t()}
          | {:error, :code_exchange_failed}
          | {:error, :code_exchange_failed, String.t()}
  def fetch_access_token(code, code_verifier) do
    # fetch the application client id and secret from the environment
    client_id = Application.get_env(:anoma, :twitter_client_id)
    client_secret = Application.get_env(:anoma, :twitter_client_secret)

    # construct the payload for the request
    body = %{
      code: code,
      grant_type: "authorization_code",
      client_id: client_id,
      redirect_uri: "#{AnomaWeb.Endpoint.url()}/index.html",
      code_verifier: code_verifier
    }

    # X requires Basic Auth with client credentials
    credentials = Base.encode64("#{client_id}:#{client_secret}")

    headers = [
      {"Authorization", "Basic #{credentials}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    # make the request to the X api
    case HTTPoison.post(@twitter_api_url, URI.encode_query(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"access_token" => access_token}} ->
            {:ok, access_token}

          {:ok, %{"error" => error}} ->
            {:error, :code_exchange_failed, error}

          _ ->
            {:error, :code_exchange_failed}
        end

      {:ok, %HTTPoison.Response{status_code: _status_code, body: response_body}} ->
        Logger.error("failed to exchange code for access token: #{response_body}")
        {:error, :code_exchange_failed}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, :code_exchange_failed, reason}
    end
  end

  @doc """
  Given an access, token, fetch the user's meta data from the X api.
  """
  @type user_meta_data :: %{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          username: String.t(),
          verified: boolean(),
          public_metrics: %{
            followers_count: number(),
            following_count: number(),
            tweet_count: number(),
            listed_count: number(),
            like_count: number(),
            media_count: number()
          },
          profile_image_url: String.t()
        }
  @spec fetch_user_meta_data(String.t()) ::
          {:ok, user_meta_data()}
          | {:error, :failed_to_fetch_user_data}
  def fetch_user_meta_data(access_token) do
    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.get(@twitter_user_meta_data_url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        result = Jason.decode(response_body, keys: :atoms)

        case result do
          {:ok, %{data: user_data}} ->
            {:ok, user_data}

          {:error, _} ->
            {:error, :failed_to_fetch_user_data}
        end

      {:ok, %HTTPoison.Response{status_code: _status_code, body: response_body}} ->
        Logger.error("failed to fetch user data: #{response_body}")
        {:error, :failed_to_fetch_user_data}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("failed to fetch user data: #{reason}")
        {:error, :failed_to_fetch_user_data}
    end
  end
end
