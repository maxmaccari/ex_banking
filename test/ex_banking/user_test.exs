defmodule ExBanking.UserTest do
  use ExUnit.Case, async: true

  alias ExBanking.User

  @name "Dummy User Account"

  setup do
    name = random_name()

    on_exit(fn ->
      :ets.delete(ExBanking.User, name)
    end)

    [name: name]
  end

  describe "start_link/1" do
    test "should start one server with the given name", %{name: name} do
      assert {:ok, pid} = User.start_link(name)
      assert name |> User.via_tuple() |> GenServer.whereis() == pid
    end

    test "should not start two servers with the same name", %{name: name} do
      assert {:ok, _} = User.start_link(name)
      assert {:error, :user_already_exists} = User.start_link(name)
    end

    test "should return :wrong_arguments error if start with non string name" do
      assert {:error, :wrong_arguments} = User.start_link(%{})
    end
  end

  describe "balance/2" do
    test "should return 0.0 for currencies without deposit", %{name: name} do
      {:ok, _} = User.start_link(name)

      assert {:ok, 0.0} = User.balance(name, "USD")
      assert {:ok, 0.0} = User.balance(name, "GBP")
      assert {:ok, 0.0} = User.balance(name, "EUR")
    end

    test "should show error if user does not exist" do
      assert {:error, :user_does_not_exist} = User.balance(@name, "USD")
    end

    test "should return :wrong_arguments error with non string name or currency", %{name: name} do
      {:ok, _} = User.start_link(name)
      assert {:error, :wrong_arguments} = User.balance(123, "USD")
      assert {:error, :wrong_arguments} = User.balance(name, 123)
    end
  end

  describe "deposit/3" do
    test "should increment the balance of the server", %{name: name} do
      {:ok, _} = User.start_link(name)

      assert {:ok, 100.0} = User.deposit(name, 100, "USD")
      assert {:ok, 150.0} = User.deposit(name, 50, "USD")

      assert {:ok, 150.0} = User.balance(name, "USD")
      assert {:ok, 0.0} = User.balance(name, "GBP")
    end

    test "should deposit in one balance not affect deposit in another balance", %{name: name} do
      {:ok, _} = User.start_link(name)

      assert {:ok, 100.0} = User.deposit(name, 100, "USD")
      assert {:ok, 150.0} = User.deposit(name, 150, "GBP")
      assert {:ok, 100.0} = User.balance(name, "USD")
      assert {:ok, 150.0} = User.balance(name, "GBP")
    end

    test "should show error if user does not exist", %{name: name} do
      assert {:error, :user_does_not_exist} = User.deposit(name, 100, "USD")
    end

    test "should return :wrong_arguments error with invalid argument types", %{name: name} do
      {:ok, _} = User.start_link(name)
      assert {:error, :wrong_arguments} = User.deposit(123, 100, "USD")
      assert {:error, :wrong_arguments} = User.deposit(name, "100", "USD")
      assert {:error, :wrong_arguments} = User.deposit(name, 100, 123)
    end

    test "should store the state into ETS in case of server restarts", %{name: name} do
      {:ok, _} = User.start_link(name)

      User.deposit(name, 100, "USD")

      stop(name)

      assert {:ok, _} = User.start_link(name)
      assert {:ok, 100.0} = User.balance(name, "USD")
    end
  end

  describe "withdraw/3" do
    test "should decrement the balance of the server", %{name: name} do
      {:ok, _} = User.start_link(name)
      User.deposit(name, 200, "USD")

      assert {:ok, 100.0} = User.withdraw(name, 100, "USD")
      assert {:ok, 50.0} = User.withdraw(name, 50, "USD")
      assert {:ok, 50.0} = User.balance(name, "USD")
    end

    test "should not decrement the balance of the server in case of not having enough money", %{
      name: name
    } do
      {:ok, _} = User.start_link(name)
      User.deposit(name, 100, "USD")

      assert {:error, :not_enough_money} = User.withdraw(name, 150, "USD")
      assert {:ok, 100.0} = User.balance(name, "USD")
    end

    test "should show error if user does not exist", %{name: name} do
      assert {:error, :user_does_not_exist} = User.withdraw(name, 100, "USD")
    end

    test "should return :wrong_arguments error with invalid argument types", %{name: name} do
      {:ok, _} = User.start_link(name)
      assert {:error, :wrong_arguments} = User.withdraw(123, 100, "USD")
      assert {:error, :wrong_arguments} = User.withdraw(name, "100", "USD")
      assert {:error, :wrong_arguments} = User.withdraw(name, 100, 123)
    end

    test "should store the state into ETS in case of server restarts", %{name: name} do
      {:ok, _} = User.start_link(name)

      User.deposit(name, 100, "USD")
      User.withdraw(name, 50, "USD")

      stop(name)

      assert {:ok, _} = User.start_link(name)
      assert {:ok, 50.0} = User.balance(name, "USD")
    end
  end

  describe "send/4" do
    setup %{name: from} do
      to = random_name()

      on_exit(fn ->
        :ets.delete(ExBanking.User, to)
      end)

      [from: from, to: to]
    end

    test "should decrement the balance of the from and increment the balance of the to", %{
      from: from,
      to: to
    } do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      User.deposit(from, 250, "USD")

      assert {:ok, 150.0, 100.0} = User.send(from, to, 100, "USD")
      assert {:ok, 150.0} = User.balance(from, "USD")
      assert {:ok, 100.0} = User.balance(to, "USD")
    end

    test "should not change the balances in case of not enought money", %{from: from, to: to} do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      User.deposit(from, 50, "USD")

      assert {:error, :not_enough_money} = User.send(from, to, 100, "USD")
      assert {:ok, 50.0} = User.balance(from, "USD")
      assert {:ok, 0.0} = User.balance(to, "USD")
    end

    test "should not change the balances in case of receiver does not exists", %{from: from} do
      {:ok, _} = User.start_link(from)
      to = "inexistent_to"

      User.deposit(from, 250, "USD")

      assert {:error, :receiver_does_not_exist} = User.send(from, to, 100, "USD")
      assert {:ok, 250.0} = User.balance(from, "USD")
    end

    test "should not allow to send money if sender does not exist", %{to: to} do
      from = "inexistent_from"
      {:ok, _} = User.start_link(to)

      assert {:error, :sender_does_not_exist} = User.send(from, to, 100, "USD")
      assert {:ok, 0.0} = User.balance(to, "USD")
    end

    test "should return any receiver error from deposit_fun arg", %{from: from, to: to} do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      User.deposit(from, 250, "USD")

      assert {:error, :error_from_receiver} =
               User.send(from, to, 100, "USD", fn _, _, _ -> {:error, :error_from_receiver} end)
    end

    test "should return :wrong_arguments error with invalid argument types", %{from: from, to: to} do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      assert {:error, :wrong_arguments} = User.send(123, to, 100, "USD")
      assert {:error, :wrong_arguments} = User.send(from, 123, 100, "USD")
      assert {:error, :wrong_arguments} = User.send(from, to, "100", "USD")
      assert {:error, :wrong_arguments} = User.send(from, to, 100, 123)
    end

    test "should store the state into ETS in case of server restarts", %{from: from, to: to} do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      User.deposit(from, 250, "USD")
      User.send(from, to, 100, "USD")

      stop(from)
      stop(to)

      assert {:ok, _} = User.start_link(from)
      assert {:ok, 150.0} = User.balance(from, "USD")

      assert {:ok, _} = User.start_link(to)
      assert {:ok, 100.0} = User.balance(to, "USD")
    end
  end

  defp random_name do
    20
    |> :rand.bytes()
    |> Base.url_encode64(padding: false)
  end

  defp stop(name) do
    name
    |> User.via_tuple()
    |> GenServer.whereis()
    |> GenServer.stop()
  end
end
