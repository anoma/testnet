defmodule Anoma.PricingTest do
  use Anoma.DataCase

  alias Anoma.Pricing

  describe "currencies" do
    alias Anoma.Pricing.Currency

    import Anoma.PricingFixtures

    @invalid_attrs %{currency: nil, price: nil}

    test "list_currencies/0 returns all currencies" do
      currency = currency_fixture()
      assert Pricing.list_currencies() == [currency]
    end

    test "get_currency!/1 returns the currency with given id" do
      currency = currency_fixture()
      assert Pricing.get_currency!(currency.id) == currency
    end

    test "create_currency/1 with valid data creates a currency" do
      valid_attrs = %{currency: "some currency", price: 120.5, timestamp: DateTime.utc_now()}

      assert {:ok, %Currency{} = currency} = Pricing.create_currency(valid_attrs)
      assert currency.currency == "some currency"
      assert currency.price == 120.5
    end

    test "create_currency/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pricing.create_currency(@invalid_attrs)
    end
  end
end
