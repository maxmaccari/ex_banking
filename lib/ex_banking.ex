defmodule ExBanking do
  @moduledoc """
  An OTP Banking API.
  """

  alias ExBanking.{User, UserSupervisor}

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
      error -> error
    end
  end

  @doc """
  Deposit a value to the given user.

  ## Examples

      iex> ExBanking.create_user("Some Deposit User")
      :ok
      iex> ExBanking.deposit("Some Deposit User", 100.0, "USD")
      {:ok, 100.0}

  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  defdelegate deposit(user, amount, currency), to: User

  @doc """
  Withdraw a value from the given user.

  ## Examples

      iex> ExBanking.create_user("Some Withdraw User")
      :ok
      iex> ExBanking.deposit("Some Withdraw User", 100.0, "USD")
      {:ok, 100.0}
      iex> ExBanking.withdraw("Some Withdraw User", 50.0, "USD")
      {:ok, 50.0}

  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  defdelegate withdraw(user, amount, currency), to: User

  @doc """
  Withdraw a value from the given user.

  ## Examples

      iex> ExBanking.create_user("Some Balance User")
      :ok
      iex> ExBanking.get_balance("Some Balance User", "USD")
      {:ok, 0.0}
      iex> ExBanking.deposit("Some Balance User", 100.0, "USD")
      {:ok, 100.0}
      iex> ExBanking.get_balance("Some Balance User", "USD")
      {:ok, 100.0}

  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  defdelegate get_balance(user, currency), to: User, as: :balance

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  defdelegate send(from_user, to_user, amount, currency), to: User
end
