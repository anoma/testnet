defmodule Anoma.BitflipTest do
  use Anoma.DataCase

  alias Anoma.Accounts
  alias Anoma.Bitflip

  import Anoma.BitflipFixtures
  import Anoma.AccountsFixtures
  import Anoma.AssetsFixtures
  import Anoma.AssetsFixtures

  describe "bets" do
    alias Anoma.Bitflip.Bet

    @invalid_attrs %{up: nil, multiplier: nil, points: nil}

    test "list_bets/0 returns all bets" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert Bitflip.list_bets() == [bet]
    end

    test "get_bet!/1 returns the bet with given id" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert Bitflip.get_bet!(bet.id) == bet
    end

    test "create_bet/1 with valid data creates a bet" do
      user = user_fixture()

      valid_attrs = %{up: true, multiplier: 42, points: 42, user_id: user.id}

      assert {:ok, %Bet{} = bet} = Bitflip.create_bet(valid_attrs)
      assert bet.up == true
      assert bet.multiplier == 42
      assert bet.points == 42
    end

    test "create_bet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bitflip.create_bet(@invalid_attrs)
    end

    test "update_bet/2 with valid data updates the bet" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      update_attrs = %{up: false, multiplier: 43, points: 43}

      assert {:ok, %Bet{} = bet} = Bitflip.update_bet(bet, update_attrs)
      assert bet.up == false
      assert bet.multiplier == 43
      assert bet.points == 43
    end

    test "update_bet/2 with invalid data returns error changeset" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert {:error, %Ecto.Changeset{}} = Bitflip.update_bet(bet, @invalid_attrs)
      assert bet == Bitflip.get_bet!(bet.id)
    end

    test "delete_bet/1 deletes the bet" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert {:ok, %Bet{}} = Bitflip.delete_bet(bet)
      assert_raise Ecto.NoResultsError, fn -> Bitflip.get_bet!(bet.id) end
    end

    test "change_bet/1 returns a bet changeset" do
      user = user_fixture()
      bet = bet_fixture(%{user_id: user.id})
      assert %Ecto.Changeset{} = Bitflip.change_bet(bet)
    end
  end

  describe "creating a bet" do
    test "create a bet" do
      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 10})

      # place a bet
      {:ok, bet} = Bitflip.place_bet(user, true, 1, 1)

      # assert the bet is not settled
      bet = Bitflip.get_bet!(bet.id)
      assert bet.settled == false

      # assert the points and fitcoins have already been deducted
      user = Accounts.get_user!(user.id)
      assert user.points == 0
      assert user.fitcoins == 0
    end

    test "create a bet with insufficient fitcoins" do
      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 0})

      # place a bet
      assert {:error, :not_enough_fitcoins} == Bitflip.place_bet(user, true, 1, 1)
    end

    test "create a bet with insufficient points" do
      # create a bet the price will go up
      user = user_fixture(%{points: 0, fitcoins: 10000})

      # place a bet
      assert {:error, :not_enough_points} == Bitflip.place_bet(user, true, 1, 1)
    end
  end

  describe "settling a bet" do
    test "create a bet" do
      # value before bet
      currency_fixture(%{currency: "BTC-USD", price: 100.0, timestamp: ~U[2025-07-01 09:00:00Z]})
      # value after bet
      currency_fixture(%{currency: "BTC-USD", price: 101.0, timestamp: ~U[2025-07-01 09:01:00Z]})

      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 10})

      # place a bet
      {:ok, bet} =
        Bitflip.create_bet(%{
          up: true,
          user_id: user.id,
          multiplier: 1,
          points: 1,
          inserted_at: ~U[2025-07-01 09:00:00Z]
        })

      # assert the bet is not settled
      bet = Bitflip.get_bet!(bet.id)
      assert bet.settled == false

      # try and settle the bet
      {:ok, _bet, :won} = Bitflip.settle_bet(bet)

      # assert the user has won points
      user = Accounts.get_user!(user.id)
      # the bet is not created using the place_bet api, so the user did not lose his coins!
      assert user.points == 3

      # assert the bet says it has been won
      bet = Bitflip.get_bet!(bet.id)
      assert bet.won == true
    end

    test "create a bet, pricing info a little later than 1 minute" do
      # value before bet
      currency_fixture(%{currency: "BTC-USD", price: 100.0, timestamp: ~U[2025-07-01 09:00:00Z]})
      # value after bet
      currency_fixture(%{currency: "BTC-USD", price: 101.0, timestamp: ~U[2025-07-01 09:02:00Z]})

      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 10})

      # place a bet
      {:ok, bet} =
        Bitflip.create_bet(%{
          up: true,
          user_id: user.id,
          multiplier: 1,
          points: 1,
          inserted_at: ~U[2025-07-01 09:00:00Z]
        })

      # assert the bet is not settled
      bet = Bitflip.get_bet!(bet.id)
      assert bet.settled == false

      # try and settle the bet
      {:ok, _bet, :won} = Bitflip.settle_bet(bet)

      # assert the user has won points
      user = Accounts.get_user!(user.id)
      # the bet is not created using the place_bet api, so the user did not lose his coins!
      assert user.points == 3

      # assert the bet says it has been won
      bet = Bitflip.get_bet!(bet.id)
      assert bet.won == true
    end

    test "create a bet, pricing info a little earlier than 1 minute" do
      # value before bet
      currency_fixture(%{currency: "BTC-USD", price: 100.0, timestamp: ~U[2025-07-01 09:00:00Z]})
      # value after bet
      currency_fixture(%{currency: "BTC-USD", price: 101.0, timestamp: ~U[2025-07-01 09:00:59Z]})

      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 10})

      # place a bet
      {:ok, bet} =
        Bitflip.create_bet(%{
          up: true,
          user_id: user.id,
          multiplier: 1,
          points: 1,
          inserted_at: ~U[2025-07-01 09:00:00Z]
        })

      # assert the bet is not settled
      bet = Bitflip.get_bet!(bet.id)
      assert bet.settled == false

      # try and settle the bet
      assert {:error, :no_price_information} == Bitflip.settle_bet(bet)
    end

    test "create a bet but lose" do
      # value before bet
      currency_fixture(%{currency: "BTC-USD", price: 100.0, timestamp: ~U[2025-07-01 09:00:00Z]})
      # value after bet
      currency_fixture(%{currency: "BTC-USD", price: 99.0, timestamp: ~U[2025-07-01 09:01:00Z]})

      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 10})

      # place a bet
      {:ok, bet} =
        Bitflip.create_bet(%{
          up: true,
          user_id: user.id,
          multiplier: 1,
          points: 1,
          inserted_at: ~U[2025-07-01 09:00:00Z]
        })

      # assert the bet is not settled
      bet = Bitflip.get_bet!(bet.id)
      assert bet.settled == false

      # try and settle the bet
      {:ok, _bet, :lost} = Bitflip.settle_bet(bet)

      # assert the user has won points
      user = Accounts.get_user!(user.id)
      # the bet is not created using the place_bet api, so the user did not lose his coins!
      assert user.points == 1

      # assert the bet says it has been won
      bet = Bitflip.get_bet!(bet.id)
      assert bet.won == false
    end

    test "create a bet no pricing info" do
      # value before bet
      currency_fixture(%{currency: "BTC-USD", price: 100.0, timestamp: ~U[2025-07-01 09:00:00Z]})
      # value after bet
      currency_fixture(%{currency: "BTC-USD", price: 99.0, timestamp: ~U[2025-07-01 09:00:01Z]})

      # create a bet the price will go up
      user = user_fixture(%{points: 1, fitcoins: 10})

      # place a bet
      {:ok, bet} =
        Bitflip.create_bet(%{
          up: true,
          user_id: user.id,
          multiplier: 1,
          points: 1,
          inserted_at: ~U[2025-07-01 09:00:00Z]
        })

      # assert the bet is not settled
      bet = Bitflip.get_bet!(bet.id)
      assert bet.settled == false

      # try and settle the bet
      assert {:error, :no_price_information} == Bitflip.settle_bet(bet)
    end
  end
end
