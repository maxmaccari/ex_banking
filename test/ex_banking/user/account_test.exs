defmodule ExBanking.User.AccountTest do
  use ExUnit.Case

  alias ExBanking.User.Account

  describe "new/1" do
    test "should create a new account with the given currency" do
      assert %Account{
               currency: "USD",
               balance: 0
             } = Account.new("usd")
    end
  end

  describe "get_balance/1" do
    test "should get the balance of the given account" do
      assert Account.balance(%Account{balance: 100}) == 100
    end
  end

  describe "deposit/2" do
    test "should increment the account balance by the given amount" do
      assert %Account{balance: 100} = Account.deposit(%Account{balance: 50}, 50)
    end
  end

  describe "withdraw/2" do
    test "should decrement the account balance by the given amount if available" do
      assert %Account{balance: 10} = Account.withdraw(%Account{balance: 50}, 40)
    end

    test "should return error when balance is not available" do
      assert :insuficient_funds = Account.withdraw(%Account{balance: 10}, 20)
    end
  end
end
