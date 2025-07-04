defmodule Anoma.Coinbase do
  @moduledoc """
  I implement a websocket connection to listen for events from the Coinbase websocket.
  """
  use WebSockex
  require Logger

  # use the sandbox during dev because the api is not free
  if Mix.env() == :prod do
    @url "wss://ws-feed.exchange.coinbase.com"
  else
    @url "wss://ws-feed-public.sandbox.exchange.coinbase.com"
  end

  def start_link(_) do
    WebSockex.start_link(@url, __MODULE__, %{})
    |> tap(&IO.inspect(&1, label: "websocket"))
  end

  def handle_connect(_conn, state) do
    # subscribe to heartbeat
    heartbeat = heartbeat_message()
    WebSockex.cast(self(), {:send, heartbeat})

    # subscribe to ticker
    ticker = subscription_message()
    WebSockex.cast(self(), {:send, ticker})

    {:ok, state}
  end

  def handle_frame({_type, msg}, state) do
    try do
      process_message(msg)
    rescue
      e ->
        Logger.error("failed to process coinbase message #{inspect(e)}")
    catch
      e ->
        Logger.error("failed to procress coinbase message #{inspect(e)}")
    end

    {:ok, state}
  end

  def handle_cast({:send, message}, state) do
    {:reply, {:text, Jason.encode!(message)}, state}
  end

  def handle_disconnect(%{reason: {:local, reason}}, state) do
    Logger.error("Local close with reason: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_disconnect(disconnect_map, state) do
    super(disconnect_map, state)
  end

  # ----------------------------------------------------------------------------
  # Helpers

  # parse the message and store it
  defp process_message(msg) do
    case parse_message(msg) do
      {:ok, %{product_id: ticker, price: price, time: timestamp}} ->
        {price, ""} = Float.parse(price)

        {:ok, _} =
          Anoma.Assets.create_currency(%{currency: ticker, price: price, timestamp: timestamp})

        Logger.info("#{inspect(DateTime.utc_now())} updated btc price")

      _ ->
        :noop
    end
  end

  # parse the message from the websocket
  defp parse_message(msg) do
    case Jason.decode(msg, keys: :atoms) do
      {:ok, map} ->
        {:ok, map}

      _ ->
        {:error, :failed_to_parse}
    end
  end

  # generate a signature for the coinbase api
  defp generate_signature do
    coinbase_secret = Application.get_env(:anoma, :coinbase_secret)

    timestamp = DateTime.utc_now() |> DateTime.to_unix(:native)
    message = "#{timestamp}GET/users/self/verify"
    hmac_key = Base.decode64!(coinbase_secret)
    signature = :crypto.mac(:hmac, :sha256, hmac_key, message) |> Base.encode64()
    {signature, timestamp}
  end

  # generate the subscription message with the api key
  def subscription_message do
    coinbase_api_key = Application.get_env(:anoma, :coinbase_api_key)
    {signature, timestamp} = generate_signature()

    %{
      timestamp: timestamp,
      type: "subscribe",
      signature: signature,
      key: coinbase_api_key,
      channels: ["ticker_batch"],
      product_ids: ["BTC-USD"],
      passphrase: ""
    }
  end

  def heartbeat_message do
    coinbase_api_key = Application.get_env(:anoma, :coinbase_api_key)
    {signature, timestamp} = generate_signature()

    %{
      timestamp: timestamp,
      type: "subscribe",
      signature: signature,
      key: coinbase_api_key,
      channels: ["heartbeat"],
      product_ids: ["BTC-USD"],
      passphrase: ""
    }
  end
end
