defmodule ExBanking.UserSupervisorTest do
  use ExUnit.Case

  alias ExBanking.{User, UserSupervisor}

  describe "start_child/1" do
    test "should start a User worker with the given name" do
      assert {:ok, pid} = UserSupervisor.start_child("some-server")
      assert "some-server" |> User.via_tuple() |> GenServer.whereis() == pid
    end

    test "should return error if try to start a server with the same name" do
      assert {:ok, _} = UserSupervisor.start_child("some-another-server")
      assert {:error, :already_started} = UserSupervisor.start_child("some-another-server")
    end
  end
end