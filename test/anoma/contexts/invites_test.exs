defmodule Anoma.InvitesTest do
  use Anoma.DataCase

  alias Anoma.Accounts
  alias Anoma.Invites

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
      valid_attrs = %{code: "INVITE123"}

      assert {:ok, %Invite{} = invite} = Invites.create_invite(valid_attrs)
      assert invite.code == "INVITE123"
    end

    test "create_invite/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Invites.create_invite(@invalid_attrs)
    end

    test "update_invite/2 with valid data updates the invite" do
      invite = invite_fixture()
      update_attrs = %{code: "UPDATED123"}

      assert {:ok, %Invite{} = invite} = Invites.update_invite(invite, update_attrs)
      assert invite.code == "UPDATED123"
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

    test "create_invite/1 generates unique codes" do
      {:ok, invite1} = Invites.create_invite(%{code: "UNIQUE1"})
      {:ok, invite2} = Invites.create_invite(%{code: "UNIQUE2"})
      assert invite1.code != invite2.code
    end

    test "create_invite/1 with duplicate code returns error" do
      {:ok, _invite} = Invites.create_invite(%{code: "DUPLICATE"})
      assert {:error, %Ecto.Changeset{}} = Invites.create_invite(%{code: "DUPLICATE"})
    end

    test "claim_invite/2 claims an invite" do
      user = user_fixture()
      invite = invite_fixture()
      assert {:ok, %Invite{} = invite} = Invites.claim_invite(invite, user)

      # check that the invite is claimed
      invite = Invites.get_invite!(invite.id) |> Repo.preload(:invitee)
      assert invite.invitee_id == user.id
    end

    test "claim_invite/2 claims an invite and adds points to the owner" do
      user = user_fixture()
      inviter = user_fixture(%{points: 0})
      invite = invite_fixture(%{owner_id: inviter.id})
      assert {:ok, %Invite{} = invite} = Invites.claim_invite(invite, user, reward: 100)

      # check that the invite is claimed
      invite = Invites.get_invite!(invite.id) |> Repo.preload(:invitee)
      assert invite.invitee_id == user.id

      # check the owner has gotten the points
      inviter = Accounts.get_user!(inviter.id)
      assert inviter.points == 100
    end

    test "claim_invite/2 claims an invite and adds points to the owner recursively" do
      # ----------------------------------------------------------------------------
      # First invite

      root = user_fixture(%{points: 0})
      root_invite = invite_fixture(%{owner_id: root.id, code: "root"})

      second = user_fixture(%{points: 0})
      second_invite = invite_fixture(%{owner_id: second.id, code: "second"})
      assert {:ok, %Invite{}} = Invites.claim_invite(root_invite, second, reward: 100)

      # check the balances
      root = Accounts.get_user!(root.id)
      assert root.points == 100

      third = user_fixture(%{points: 0, code: "third"})
      assert {:ok, %Invite{}} = Invites.claim_invite(second_invite, third, reward: 100)

      # # check the balances
      # root = Accounts.get_user!(root.id)
      # assert root.points == 10

      # second = Accounts.get_user!(second.id)
      # assert second.points == 10

      # third = Accounts.get_user!(third.id)
      # assert third.points == 1
    end

    test "claim_invite/2 a claimed invite fails" do
      user = user_fixture()
      invite = invite_fixture()
      assert {:ok, %Invite{} = invite} = Invites.claim_invite(invite, user)
      assert invite.invitee_id == user.id

      # claim second time and expect an error
      other_user = user_fixture()
      assert {:error, :invite_already_claimed} = Invites.claim_invite(invite, other_user)

      # ensure the invite is still claimed by the first user
      invite = Invites.get_invite!(invite.id)
      assert invite.invitee_id == user.id
    end

    test "invite tree empty" do
      user = user_fixture()
      assert Invites.invite_tree(user) == {user.id, [], 0}
    end

    test "invite tree with one invited user" do
      user = user_fixture()
      invited_user = user_fixture()

      # claim this invite by another user
      invite = invite_fixture(%{owner_id: user.id})
      assert {:ok, %Invite{} = _invite} = Invites.claim_invite(invite, invited_user)

      # assert the invite exists

      assert Invites.invite_tree(user) == {user.id, [{invited_user.id, [], 0}], 0}
    end

    test "invite tree with multiple invited user" do
      user = user_fixture()

      # invite a few users
      invited_user_ids =
        for _ <- 1..10 do
          invited_user = user_fixture()

          invite =
            invite_fixture(%{
              owner_id: user.id,
              code: Base.encode16(:crypto.strong_rand_bytes(32))
            })

          assert {:ok, %Invite{} = _invite} = Invites.claim_invite(invite, invited_user)
          invited_user.id
        end

      # assert the invite exists
      invite_tree = Enum.map(invited_user_ids, &{&1, [], 0})
      assert Invites.invite_tree(user) == {user.id, invite_tree, 0}
    end

    test "invite tree with multiple invited users and invites for those users." do
      # start with a single user, that will invite 10 users.
      user = user_fixture()

      create_invites = fn depth, user, create_invites ->
        # create a user that will use this invite
        for _ <- 1..5 do
          invite =
            invite_fixture(%{
              owner_id: user.id,
              code: Base.encode16(:crypto.strong_rand_bytes(32))
            })

          invited_user = user_fixture()
          assert {:ok, %Invite{} = _invite} = Invites.claim_invite(invite, invited_user)

          # create invites for this user too
          subtree =
            if depth < 2 do
              create_invites.(depth + 1, invited_user, create_invites)
            else
              []
            end

          {invited_user.id, subtree, 0}
        end
      end

      tree = create_invites.(0, user, create_invites)

      # assert the invite exists
      assert Invites.invite_tree(user) == {user.id, tree, 0}
    end

    test "invite tree with multiple invited users and invites for those users, and points are computed." do
      user = user_fixture()
      invited_user = user_fixture()

      # claim this invite by another user
      invite = invite_fixture(%{owner_id: user.id})
      assert {:ok, %Invite{} = _invite} = Invites.claim_invite(invite, invited_user, reward: 10)

      # assert the invite exists

      assert Invites.invite_tree(user) == {user.id, [{invited_user.id, [], 10}], 0}
    end
  end
end
