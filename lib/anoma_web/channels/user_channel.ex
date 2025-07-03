defmodule AnomaWeb.UserChannel do
  @moduledoc """
  This module handles the websocket communication with the user.
  This channel deals with unique users and is considered safe and authenticated.
  """
  use AnomaWeb, :channel

  alias Anoma.Accounts
  alias Anoma.Accounts.User
  alias Anoma.DailyPoints
  alias Anoma.DailyPoints.DailyPoint
  alias AnomaWeb.Plugs.AuthPlug

  require Logger

  @impl true
  def join("user:" <> channel_user_id, %{"jwt" => jwt}, socket) do
    # verify the jwt token
    with {:ok, token} <- AuthPlug.verify_token(jwt),
         # fetch the user id from the token
         user_id <- Map.get(token, "user_id"),
         # query the user to ensure it really exists in the backend
         user when not is_nil(user) <- Accounts.get_user(user_id) do
      user = Anoma.Repo.preload(user, [:invite, :invites, :daily_points])
      # the user in the token should be the same as the user id in the channel
      if "#{user_id}" == channel_user_id do
        # subscribe to updates from the database
        EctoWatch.subscribe({User, :updated}, user_id)
        EctoWatch.subscribe({DailyPoint, :inserted})
        socket = assign(socket, :current_user_id, user.id)
        {:ok, user, socket}
      else
        {:error, %{reason: "unauthorized"}}
      end
    else
      # the user did not exist in the backend
      nil ->
        {:error, %{reason: "user not found"}}
    end
  end

  @impl true
  def handle_in(_msg, _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({{User, :updated}, %{id: user_id}}, socket) do
    user = Accounts.get_user!(user_id)
    user = Anoma.Repo.preload(user, [:invite, :invites, :daily_points])
    push(socket, "profile_update", %{user: user})
    {:noreply, socket}
  end

  @impl true
  def handle_info({{DailyPoint, :inserted}, %{id: id}}, socket) do
    {:ok, daily_point} = DailyPoints.get_daily_point(id)

    if socket.assigns.current_user_id == daily_point.user.id do
      user = Accounts.get_user!(socket.assigns.current_user_id)
      user = Anoma.Repo.preload(user, [:invite, :invites, :daily_points])
      push(socket, "profile_update", %{user: user})
    end

    {:noreply, socket}
  end
end
