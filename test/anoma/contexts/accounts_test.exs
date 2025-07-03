defmodule Anoma.AccountsTest do
  use Anoma.DataCase

  alias Anoma.Accounts
  alias Anoma.Invites
  alias Anoma.Invites.Invite

  describe "users" do
    alias Anoma.Accounts.User

    import Anoma.AccountsFixtures

    @invalid_attrs %{email: nil, confirmed_at: nil, points: nil, eth_address: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{
        email: "some email",
        confirmed_at: ~U[2025-06-11 12:43:00Z],
        points: 42,
        eth_address: "some eth_address"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.email == "some email"
      assert user.confirmed_at == ~U[2025-06-11 12:43:00Z]
      assert user.points == 42
      assert user.eth_address == "some eth_address"
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()

      update_attrs = %{
        email: "some updated email",
        confirmed_at: ~U[2025-06-12 12:43:00Z],
        points: 43,
        eth_address: "some updated eth_address"
      }

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.email == "some updated email"
      assert user.confirmed_at == ~U[2025-06-12 12:43:00Z]
      assert user.points == 43
      assert user.eth_address == "some updated eth_address"
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "update_user_eth_address/2 with valid eth_address updates the user" do
      user = user_fixture()
      new_eth_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, %User{} = updated_user} =
               Accounts.update_user_eth_address(user, new_eth_address)

      assert updated_user.eth_address == new_eth_address
      assert updated_user.id == user.id
    end

    test "add_points_to_user/2 adds points to user with existing points" do
      user = user_fixture(%{points: 100})

      assert {:ok, %User{} = updated_user} = Accounts.add_points_to_user(user, 50)
      assert updated_user.points == 150
      assert updated_user.id == user.id
    end

    test "add_points_to_user/2 subtracts points when given negative value" do
      user = user_fixture(%{points: 200})

      assert {:ok, %User{} = updated_user} = Accounts.add_points_to_user(user, -50)
      assert updated_user.points == 150
      assert updated_user.id == user.id
    end

    test "add_points_to_user/2 handles zero points" do
      user = user_fixture(%{points: 100})

      assert {:ok, %User{} = updated_user} = Accounts.add_points_to_user(user, 0)
      assert updated_user.points == 100
      assert updated_user.id == user.id
    end

    test "add_points_to_user/2 adds points to the person who invited this user too" do
      user = user_fixture(%{points: 0})
      invited_user = user_fixture(%{points: 0})

      # claim this invite by another user
      invite = invite_fixture(%{owner_id: user.id})
      assert {:ok, %Invite{} = _invite} = Invites.claim_invite(invite, invited_user)

      # add points to the invited user
      assert {:ok, %User{} = updated_user} = Accounts.add_points_to_user(invited_user, 10)
      assert updated_user.points == 10
      assert updated_user.id == invited_user.id

      # the inviter has 1 point
      user = Accounts.get_user!(user.id)
      assert user.points == 1
    end

    test "add_points_to_user/2 adds points to the person who invited this user too, and their inviter too" do
      # creeate a chain of users that each invite the next one
      users = for _ <- 1..10, do: user_fixture(%{points: 0})

      Enum.scan(users, fn invitee, inviter ->
        # create an invite for the inviter
        invite =
          invite_fixture(%{
            owner_id: inviter.id,
            code: Base.encode16(:crypto.strong_rand_bytes(8))
          })

        # let the invitee use this invite
        assert {:ok, %Invite{} = _invite} = Invites.claim_invite(invite, invitee)

        invitee
      end)

      last_user = List.last(users)

      # verify that each user
      # add points to the invited user
      assert {:ok, %User{} = updated_user} = Accounts.add_points_to_user(last_user, 1_000_000_000)
      assert updated_user.points == 1_000_000_000
      assert updated_user.id == last_user.id

      # each user should have 10% of the points their inviter got
      Enum.reduce(users, 1, fn user, expected_points ->
        user = Accounts.get_user!(user.id)
        assert user.points == expected_points
        expected_points * 10
      end)
    end

    test "update_user_eth_address/2 with different valid eth_address updates the user" do
      user = user_fixture(%{eth_address: "0xoriginaladdress"})
      new_eth_address = "0x9876543210fedcba9876543210fedcba98765432"

      assert {:ok, %User{} = updated_user} =
               Accounts.update_user_eth_address(user, new_eth_address)

      assert updated_user.eth_address == new_eth_address
      assert updated_user.id == user.id
    end

    test "add_points_to_user/2 adds points to user with zero points" do
      user = user_fixture(%{points: 0})

      assert {:ok, %User{} = updated_user} = Accounts.add_points_to_user(user, 25)
      assert updated_user.points == 25
      assert updated_user.id == user.id
    end
  end

  describe "invites" do
    alias Anoma.Invites.Invite

    import Anoma.AccountsFixtures

    @invalid_attrs %{code: nil}

    test "list_invites/0 returns all invites" do
      invite = invite_fixture()
      assert Invites.list_invites() == [invite]
    end

    test "get_invite!/1 returns the invite with given id" do
      invite = invite_fixture()
      assert Invites.get_invite!(invite.id) == invite
    end

    test "create_invite/1 with valid data creates a invite" do
      valid_attrs = %{code: "some code"}

      assert {:ok, %Invite{} = invite} = Invites.create_invite(valid_attrs)
      assert invite.code == "some code"
    end

    test "create_invite/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Invites.create_invite(@invalid_attrs)
    end

    test "update_invite/2 with valid data updates the invite" do
      invite = invite_fixture()
      update_attrs = %{code: "some updated code"}

      assert {:ok, %Invite{} = invite} = Invites.update_invite(invite, update_attrs)
      assert invite.code == "some updated code"
    end

    test "update_invite/2 with invalid data returns error changeset" do
      invite = invite_fixture()
      assert {:error, %Ecto.Changeset{}} = Invites.update_invite(invite, @invalid_attrs)
      assert invite == Invites.get_invite!(invite.id)
    end

    test "delete_invite/1 deletes the invite" do
      invite = invite_fixture()
      assert {:ok, %Invite{}} = Invites.delete_invite(invite)
      assert_raise Ecto.NoResultsError, fn -> Invites.get_invite!(invite.id) end
    end

    test "change_invite/1 returns a invite changeset" do
      invite = invite_fixture()
      assert %Ecto.Changeset{} = Invites.change_invite(invite)
    end
  end
end
