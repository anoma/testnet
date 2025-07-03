defmodule Anoma.AssetsTest do
  use Anoma.DataCase

  alias Anoma.Assets

  describe "currencies" do
    alias Anoma.Assets.Currency

    import Anoma.AssetsFixtures

    @invalid_attrs %{currency: nil, price: nil}

    test "list_currencies/0 returns all currencies" do
      currency = currency_fixture()
      assert Assets.list_currencies() == [currency]
    end

    test "get_currency!/1 returns the currency with given id" do
      currency = currency_fixture()
      assert Assets.get_currency!(currency.id) == currency
    end

    test "create_currency/1 with valid data creates a currency" do
      valid_attrs = %{currency: "some currency", price: 120.5, timestamp: DateTime.utc_now()}

      assert {:ok, %Currency{} = currency} = Assets.create_currency(valid_attrs)
      assert currency.currency == "some currency"
      assert currency.price == 120.5
    end

    test "create_currency/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_currency(@invalid_attrs)
    end
  end
end
