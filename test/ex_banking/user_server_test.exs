defmodule ExBanking.UserServerTest do
  use ExUnit.Case

  alias ExBanking.UserServer

  describe "start_link/1" do
    test "should start one server with the given name" do
      name = "Dummy User Account"
      assert {:ok, ^name} = UserServer.start_link(name)
    end

    test "should not start two servers with the same name" do
      name = "Dummy User Account"
      assert {:ok, ^name} = UserServer.start_link(name)
      assert {:error, :already_started} = UserServer.start_link(name)
    end
  end

  describe "balance/2" do
    test "should return 0.0 for currencies without deposit" do
      name = "Dummy User Account"
      {:ok, _} = UserServer.start_link(name)

      assert UserServer.balance(name, "USD") == 0.0
      assert UserServer.balance(name, "GBP") == 0.0
      assert UserServer.balance(name, "EUR") == 0.0
    end
  end
end
