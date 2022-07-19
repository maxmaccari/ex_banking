defmodule ExBanking.UserServerTest do
  use ExUnit.Case

  alias ExBanking.UserServer

  @name "Dummy User Account"

  describe "start_link/1" do
    test "should start one server with the given name" do
      assert {:ok, @name} = UserServer.start_link(@name)
    end

    test "should not start two servers with the same name" do
      assert {:ok, @name} = UserServer.start_link(@name)
      assert {:error, :already_started} = UserServer.start_link(@name)
    end
  end

  describe "balance/2" do
    test "should return 0.0 for currencies without deposit" do
      {:ok, _} = UserServer.start_link(@name)

      assert UserServer.balance(@name, "USD") == 0.0
      assert UserServer.balance(@name, "GBP") == 0.0
      assert UserServer.balance(@name, "EUR") == 0.0
    end
  end

  describe "deposit/3" do
    test "should increment the balance of the server" do
      {:ok, _} = UserServer.start_link(@name)

      assert {:ok, 100.0} = UserServer.deposit(@name, "USD", 100)
      assert {:ok, 150.0} = UserServer.deposit(@name, "USD", 50)
      assert UserServer.balance(@name, "USD") == 150.0
      assert UserServer.balance(@name, "GBP") == 0.0
    end

    test "should deposit in one balance not affect deposit in another balance" do
      {:ok, _} = UserServer.start_link(@name)

      assert {:ok, 100.0} = UserServer.deposit(@name, "USD", 100)
      assert {:ok, 150.0} = UserServer.deposit(@name, "GBP", 150)
      assert UserServer.balance(@name, "USD") == 100.0
      assert UserServer.balance(@name, "GBP") == 150.0
    end
  end

  describe "withdraw/3" do
    test "should decrement the balance of the server" do
      {:ok, _} = UserServer.start_link(@name)
      UserServer.deposit(@name, "USD", 200)

      assert {:ok, 100.0} = UserServer.withdraw(@name, "USD", 100)
      assert {:ok, 50.0} = UserServer.withdraw(@name, "USD", 50)
      assert UserServer.balance(@name, "USD") == 50.0
    end

    test "should not decrement the balance of the server in case of not having enough money" do
      {:ok, _} = UserServer.start_link(@name)
      UserServer.deposit(@name, "USD", 100)

      assert {:error, :not_enough_money} = UserServer.withdraw(@name, "USD", 150)
      assert UserServer.balance(@name, "USD") == 100.0
    end
  end
end
