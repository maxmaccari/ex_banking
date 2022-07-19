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

      assert {:ok, 0.0} = UserServer.balance(@name, "USD")
      assert {:ok, 0.0} = UserServer.balance(@name, "GBP")
      assert {:ok, 0.0} = UserServer.balance(@name, "EUR")
    end

    test "should show error if user does not exist" do
      assert {:error, :user_does_not_exist} = UserServer.balance(@name, "USD")
    end
  end

  describe "deposit/3" do
    test "should increment the balance of the server" do
      {:ok, _} = UserServer.start_link(@name)

      assert {:ok, 100.0} = UserServer.deposit(@name, "USD", 100)
      assert {:ok, 150.0} = UserServer.deposit(@name, "USD", 50)

      assert {:ok, 150.0} = UserServer.balance(@name, "USD")
      assert {:ok, 0.0} = UserServer.balance(@name, "GBP")
    end

    test "should deposit in one balance not affect deposit in another balance" do
      {:ok, _} = UserServer.start_link(@name)

      assert {:ok, 100.0} = UserServer.deposit(@name, "USD", 100)
      assert {:ok, 150.0} = UserServer.deposit(@name, "GBP", 150)
      assert {:ok, 100.0} = UserServer.balance(@name, "USD")
      assert {:ok, 150.0} = UserServer.balance(@name, "GBP")
    end

    test "should show error if user does not exist" do
      assert {:error, :user_does_not_exist} = UserServer.deposit(@name, "USD", 100)
    end
  end

  describe "withdraw/3" do
    test "should decrement the balance of the server" do
      {:ok, _} = UserServer.start_link(@name)
      UserServer.deposit(@name, "USD", 200)

      assert {:ok, 100.0} = UserServer.withdraw(@name, "USD", 100)
      assert {:ok, 50.0} = UserServer.withdraw(@name, "USD", 50)
      assert {:ok, 50.0} = UserServer.balance(@name, "USD")
    end

    test "should not decrement the balance of the server in case of not having enough money" do
      {:ok, _} = UserServer.start_link(@name)
      UserServer.deposit(@name, "USD", 100)

      assert {:error, :not_enough_money} = UserServer.withdraw(@name, "USD", 150)
      assert {:ok, 100.0} = UserServer.balance(@name, "USD")
    end

    test "should show error if user does not exist" do
      assert {:error, :user_does_not_exist} = UserServer.withdraw(@name, "USD", 100)
    end
  end

  describe "send/4" do
    test "should decrement the balance of the from and increment the balance of the to" do
      {:ok, from} = UserServer.start_link("From Server")
      {:ok, to} = UserServer.start_link("To Server")

      UserServer.deposit(from, "USD", 250)

      assert {:ok, 150.0, 100.0} = UserServer.send(from, to, "USD", 100)
      assert {:ok, 150.0} = UserServer.balance(from, "USD")
      assert {:ok, 100.0} = UserServer.balance(to, "USD")
    end

    test "should not change the balances in case of not enought money" do
      {:ok, from} = UserServer.start_link("From Server")
      {:ok, to} = UserServer.start_link("To Server")

      UserServer.deposit(from, "USD", 50)

      assert {:error, :not_enough_money} = UserServer.send(from, to, "USD", 100)
      assert {:ok, 50.0} = UserServer.balance(from, "USD")
      assert {:ok, 0.0} = UserServer.balance(to, "USD")
    end

    test "should not change the balances in case of receiver does not exists" do
      {:ok, from} = UserServer.start_link("From Server")
      to = "To Server"

      UserServer.deposit(from, "USD", 250)

      assert {:error, :receiver_does_not_exist} = UserServer.send(from, to, "USD", 100)
      assert {:ok, 250.0} = UserServer.balance(from, "USD")
    end

    test "should not allow to send money if sender does not exist" do
      from = "From Server"
      {:ok, to} = UserServer.start_link("To Server")

      assert {:error, :sender_does_not_exist} = UserServer.send(from, to, "USD", 100)
      assert {:ok, 0.0} = UserServer.balance(to, "USD")
    end
  end
end
