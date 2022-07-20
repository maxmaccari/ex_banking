defmodule ExBanking.UserInfo.AccountTest do
  use ExUnit.Case, async: true

  alias ExBanking.UserInfo.Account

  describe "new/1" do
    test "should create a new account with the given currency" do
      assert %Account{
               currency: "USD",
               balance: %Decimal{}
             } = Account.new("usd")
    end

    test "should create a new account with the given currency and initial balance" do
      expected_balance = Decimal.new(100)

      assert %Account{
               currency: "USD",
               balance: ^expected_balance
             } = Account.new("usd", 100)
    end
  end

  @account %Account{balance: Decimal.new("100.00")}

  describe "get_balance/1" do
    test "should get the balance of the given account in float representation" do
      assert Account.balance(@account) == 100.0
    end
  end

  describe "deposit/2" do
    test "should increment the account balance by the given amount" do
      expected_balance = Decimal.new("150.00")
      assert %Account{balance: ^expected_balance} = Account.deposit(@account, 50.0)
    end

    test "should work with integer" do
      expected_balance = Decimal.new("150.00")
      assert %Account{balance: ^expected_balance} = Account.deposit(@account, 50)
    end

    test "should use two decimal precision ignoring rest of decimal places" do
      expected_balance = Decimal.new("150.49")
      assert %Account{balance: ^expected_balance} = Account.deposit(@account, 50.49876)
    end
  end

  describe "withdraw/2" do
    test "should decrement the account balance by the given amount if available" do
      expected_balance = Decimal.new("50.00")
      assert %Account{balance: ^expected_balance} = Account.withdraw(@account, 50.0)
    end

    test "should return error when balance is not available" do
      assert :not_enough_money = Account.withdraw(@account, 120.0)
    end

    test "should work with integer" do
      expected_balance = Decimal.new("50.00")
      assert %Account{balance: ^expected_balance} = Account.withdraw(@account, 50)
    end

    test "should use two decimal precision ignoring rest of decimal places" do
      expected_balance = Decimal.new("49.51")
      assert %Account{balance: ^expected_balance} = Account.withdraw(@account, 50.49876)
    end
  end
end
