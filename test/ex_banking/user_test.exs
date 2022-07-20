defmodule ExBanking.UserTest do
  use ExUnit.Case

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
      assert {:ok, ^name} = User.start_link(name)
    end

    test "should not start two servers with the same name", %{name: name} do
      assert {:ok, ^name} = User.start_link(name)
      assert {:error, :already_started} = User.start_link(name)
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
  end

  describe "deposit/3" do
    test "should increment the balance of the server", %{name: name} do
      {:ok, _} = User.start_link(name)

      assert {:ok, 100.0} = User.deposit(name, "USD", 100)
      assert {:ok, 150.0} = User.deposit(name, "USD", 50)

      assert {:ok, 150.0} = User.balance(name, "USD")
      assert {:ok, 0.0} = User.balance(name, "GBP")
    end

    test "should deposit in one balance not affect deposit in another balance", %{name: name} do
      {:ok, _} = User.start_link(name)

      assert {:ok, 100.0} = User.deposit(name, "USD", 100)
      assert {:ok, 150.0} = User.deposit(name, "GBP", 150)
      assert {:ok, 100.0} = User.balance(name, "USD")
      assert {:ok, 150.0} = User.balance(name, "GBP")
    end

    test "should show error if user does not exist", %{name: name} do
      assert {:error, :user_does_not_exist} = User.deposit(name, "USD", 100)
    end

    test "should store the state into ETS in case of server restarts", %{name: name} do
      {:ok, _} = User.start_link(name)

      User.deposit(name, "USD", 100)

      stop(name)

      assert {:ok, ^name} = User.start_link(name)
      assert {:ok, 100.0} = User.balance(name, "USD")
    end
  end

  describe "withdraw/3" do
    test "should decrement the balance of the server", %{name: name} do
      {:ok, _} = User.start_link(name)
      User.deposit(name, "USD", 200)

      assert {:ok, 100.0} = User.withdraw(name, "USD", 100)
      assert {:ok, 50.0} = User.withdraw(name, "USD", 50)
      assert {:ok, 50.0} = User.balance(name, "USD")
    end

    test "should not decrement the balance of the server in case of not having enough money", %{
      name: name
    } do
      {:ok, _} = User.start_link(name)
      User.deposit(name, "USD", 100)

      assert {:error, :not_enough_money} = User.withdraw(name, "USD", 150)
      assert {:ok, 100.0} = User.balance(name, "USD")
    end

    test "should show error if user does not exist", %{name: name} do
      assert {:error, :user_does_not_exist} = User.withdraw(name, "USD", 100)
    end

    test "should store the state into ETS in case of server restarts", %{name: name} do
      {:ok, _} = User.start_link(name)

      User.deposit(name, "USD", 100)
      User.withdraw(name, "USD", 50)

      stop(name)

      assert {:ok, ^name} = User.start_link(name)
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

      User.deposit(from, "USD", 250)

      assert {:ok, 150.0, 100.0} = User.send(from, to, "USD", 100)
      assert {:ok, 150.0} = User.balance(from, "USD")
      assert {:ok, 100.0} = User.balance(to, "USD")
    end

    test "should not change the balances in case of not enought money", %{from: from, to: to} do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      User.deposit(from, "USD", 50)

      assert {:error, :not_enough_money} = User.send(from, to, "USD", 100)
      assert {:ok, 50.0} = User.balance(from, "USD")
      assert {:ok, 0.0} = User.balance(to, "USD")
    end

    test "should not change the balances in case of receiver does not exists", %{from: from} do
      {:ok, _} = User.start_link(from)
      to = "inexistent_to"

      User.deposit(from, "USD", 250)

      assert {:error, :receiver_does_not_exist} = User.send(from, to, "USD", 100)
      assert {:ok, 250.0} = User.balance(from, "USD")
    end

    test "should not allow to send money if sender does not exist", %{to: to} do
      from = "inexistent_from"
      {:ok, _} = User.start_link(to)

      assert {:error, :sender_does_not_exist} = User.send(from, to, "USD", 100)
      assert {:ok, 0.0} = User.balance(to, "USD")
    end

    test "should store the state into ETS in case of server restarts", %{from: from, to: to} do
      {:ok, _} = User.start_link(from)
      {:ok, _} = User.start_link(to)

      User.deposit(from, "USD", 250)
      User.send(from, to, "USD", 100)

      stop(from)
      stop(to)

      assert {:ok, ^from} = User.start_link(from)
      assert {:ok, 150.0} = User.balance(from, "USD")

      assert {:ok, ^to} = User.start_link(to)
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
