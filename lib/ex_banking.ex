defmodule ExBanking do
  @moduledoc """
  An OTP Banking API.
  """

  alias ExBanking.UserSupervisor

  @doc """
  Create a new user with the given name.

  ## Examples

      iex> ExBanking.create_user("Some User")
      :ok

  """
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    case UserSupervisor.start_child(user) do
      {:ok, _pid} -> :ok
      {:error, :already_started} -> {:error, :user_already_exists}
      error -> error
    end
  end
end
