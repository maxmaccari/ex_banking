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

  defp random_name do
    20
    |> :rand.bytes()
    |> Base.url_encode64(padding: false)
  end
end
