defmodule Anoma.BetsTest do
  use Anoma.DataCase

  alias Anoma.Bets

  describe "bets" do
    alias Anoma.Pricing.Bet

    import Anoma.BetsFixtures
    import Anoma.AccountsFixtures

    @invalid_attrs %{up: nil, multiplier: nil, points: nil}

    test "list_bets/0 returns all bets" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert Bets.list_bets() == [bet]
    end

    test "get_bet!/1 returns the bet with given id" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert Bets.get_bet!(bet.id) == bet
    end

    test "create_bet/1 with valid data creates a bet" do
      user = user_fixture()

      valid_attrs = %{up: true, multiplier: 42, points: 42, user_id: user.id}

      assert {:ok, %Bet{} = bet} = Bets.create_bet(valid_attrs)
      assert bet.up == true
      assert bet.multiplier == 42
      assert bet.points == 42
    end

    test "create_bet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bets.create_bet(@invalid_attrs)
    end

    test "update_bet/2 with valid data updates the bet" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      update_attrs = %{up: false, multiplier: 43, points: 43}

      assert {:ok, %Bet{} = bet} = Bets.update_bet(bet, update_attrs)
      assert bet.up == false
      assert bet.multiplier == 43
      assert bet.points == 43
    end

    test "update_bet/2 with invalid data returns error changeset" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = Bets.update_bet(bet, @invalid_attrs)
      assert bet == Bets.get_bet!(bet.id)
    end

    test "delete_bet/1 deletes the bet" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert {:ok, %Bet{}} = Bets.delete_bet(bet)
      assert_raise Ecto.NoResultsError, fn -> Bets.get_bet!(bet.id) end
    end

    test "change_bet/1 returns a bet changeset" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = Bets.change_bet(bet)
    end
  end
end
