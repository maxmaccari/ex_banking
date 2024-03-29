defmodule ExBanking.UserInfoTest do
  use ExUnit.Case, async: true

  alias ExBanking.UserInfo
  alias ExBanking.UserInfo.Account

  describe "new/1" do
    test "should create a new user" do
      assert %UserInfo{name: "My Name", accounts: %{}} = UserInfo.new("My Name")
    end
  end

  describe "balance/2" do
    test "should return 0.0 if there's no account with the given currency" do
      user = UserInfo.new("My Name")
      assert UserInfo.balance(user, "USD") == 0.0
    end

    test "should return the account balance if there's account with the given currency case sensitive" do
      user = UserInfo.new("My Name")

      user = %{
        user
        | accounts: %{"USD" => Account.new("USD", 100)}
      }

      assert UserInfo.balance(user, "USD") == 100.0
      assert UserInfo.balance(user, "usd") == 0.0
    end
  end

  describe "deposit/3" do
    test "should deposit the given amount to the given account and currency" do
      user = UserInfo.new("My Name")

      assert %UserInfo{} = user = UserInfo.deposit(user, 100, "USD")
      assert UserInfo.balance(user, "USD") == 100.0

      assert %UserInfo{} = user = UserInfo.deposit(user, 50, "USD")
      assert UserInfo.balance(user, "USD") == 150.0
    end
  end

  describe "withdraw/3" do
    test "should withdraw the given amount from the given account and currency" do
      user = "My Name" |> UserInfo.new() |> UserInfo.deposit(100, "USD")

      assert %UserInfo{} = user = UserInfo.withdraw(user, 50, "USD")
      assert UserInfo.balance(user, "USD") == 50.0

      assert %UserInfo{} = user = UserInfo.withdraw(user, 25, "USD")
      assert UserInfo.balance(user, "USD") == 25.0
    end

    test "should return :insuficient_funds in case of amount bigger than balance" do
      user = "My Name" |> UserInfo.new() |> UserInfo.deposit(100, "USD")

      assert :not_enough_money = UserInfo.withdraw(user, 150, "USD")
    end
  end
end
