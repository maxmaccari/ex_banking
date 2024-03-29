defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking

  describe "create_user/1" do
    test "should create a new user if it doesn't exist" do
      assert :ok = ExBanking.create_user(random_name())
    end

    test "should not allow creating a user that exists" do
      used_name = random_name()
      assert :ok = ExBanking.create_user(used_name)
      assert {:error, :user_already_exists} = ExBanking.create_user(used_name)
    end

    test "should allow creating user only with string args" do
      assert {:error, :wrong_arguments} = ExBanking.create_user(123)
    end
  end

  describe "deposit/3, withdraw/3, and get_balance/2" do
    test "should allow to deposit, withdraw and get_balance from user" do
      name = random_name()
      assert :ok = ExBanking.create_user(name)

      assert {:ok, 100.0} = ExBanking.deposit(name, 100, "USD")
      assert {:ok, 50.0} = ExBanking.withdraw(name, 50, "USD")
      assert {:ok, 50.0} = ExBanking.get_balance(name, "USD")
      assert {:error, :not_enough_money} = ExBanking.withdraw(name, 100, "USD")
      assert {:ok, 50.0} = ExBanking.get_balance(name, "USD")
    end

    test "should one currency not interfere in another" do
      name = random_name()
      assert :ok = ExBanking.create_user(name)

      assert {:ok, 100.0} = ExBanking.deposit(name, 100, "USD")
      assert {:ok, 50.0} = ExBanking.deposit(name, 50, "GBP")
      assert {:ok, 50.0} = ExBanking.withdraw(name, 50, "USD")
      assert {:ok, 0.0} = ExBanking.withdraw(name, 50, "GBP")
      assert {:ok, 50.0} = ExBanking.get_balance(name, "USD")
      assert {:ok, 0.0} = ExBanking.get_balance(name, "GBP")
    end

    test "should return errors if user doesn't exist" do
      name = random_name()

      assert {:error, :user_does_not_exist} = ExBanking.deposit(name, 100, "USD")
      assert {:error, :user_does_not_exist} = ExBanking.withdraw(name, 50, "USD")
      assert {:error, :user_does_not_exist} = ExBanking.get_balance(name, "GBP")
    end

    test "should return wrong arguments error" do
      name = random_name()

      assert {:error, :wrong_arguments} = ExBanking.deposit(name, "100", "USD")
      assert {:error, :wrong_arguments} = ExBanking.withdraw(name, "50", "USD")
      assert {:error, :wrong_arguments} = ExBanking.get_balance(name, 123)
    end
  end

  describe "send/4" do
    test "should send the money from one user to another user" do
      from = random_name()
      to = random_name()

      ExBanking.create_user(from)
      ExBanking.deposit(from, 250, "USD")

      ExBanking.create_user(to)

      assert {:ok, 150.0, 100.0} = ExBanking.send(from, to, 100, "USD")
      assert {:ok, 150.0} = ExBanking.get_balance(from, "USD")
      assert {:ok, 100.0} = ExBanking.get_balance(to, "USD")
    end

    test "should not send the the money in case of not enought money" do
      from = random_name()
      to = random_name()

      ExBanking.create_user(from)
      ExBanking.deposit(from, 50, "USD")

      ExBanking.create_user(to)

      assert {:error, :not_enough_money} = ExBanking.send(from, to, 100, "USD")
      assert {:ok, 50.0} = ExBanking.get_balance(from, "USD")
      assert {:ok, 0.0} = ExBanking.get_balance(to, "USD")
    end

    test "should not send the the money in case of one of them does't exist" do
      from = random_name()
      to = random_name()

      ExBanking.create_user(from)
      ExBanking.deposit(from, 250, "USD")
      ExBanking.create_user(to)

      assert {:error, :sender_does_not_exist} = ExBanking.send("invalid", to, 100, "USD")
      assert {:error, :receiver_does_not_exist} = ExBanking.send(from, "invalid", 100, "USD")
    end
  end

  defp random_name do
    20
    |> :rand.bytes()
    |> Base.url_encode64(padding: false)
  end
end
