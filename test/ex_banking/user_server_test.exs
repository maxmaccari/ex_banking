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
end
