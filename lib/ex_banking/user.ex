defmodule ExBanking.User do
  @moduledoc """
  The User structure.

  This structure handle accounts and it currencies.
  """

  defstruct name: nil, accounts: %{}

  alias ExBanking.User.Account

  @type t :: %__MODULE__{
          name: String.t(),
          accounts: %{String.t() => Account.t()}
        }

  @spec new(String.t()) :: ExBanking.User.t()
  def new(name) do
    %__MODULE__{name: name}
  end

  @spec balance(t(), String.t()) :: float
  def balance(%__MODULE__{accounts: accounts}, currency) do
    accounts
    |> Map.get(String.upcase(currency), Account.new(currency))
    |> Account.balance()
  end

  @spec deposit(t(), String.t(), number) :: t()
  def deposit(%__MODULE__{accounts: accounts} = user, currency, amount) do
    accounts =
      Map.update(
        accounts,
        String.upcase(currency),
        Account.new(currency, amount),
        &Account.deposit(&1, amount)
      )

    %{user | accounts: accounts}
  end

  @spec withdraw(t(), String.t(), number) :: :not_enough_money | t()
  def withdraw(%__MODULE__{accounts: accounts} = user, currency, amount) do
    currency = String.upcase(currency)
    account = Map.get(accounts, currency, Account.new(currency))

    case Account.withdraw(account, amount) do
      %Account{} = account ->
        %{user | accounts: Map.put(accounts, currency, account)}

      :not_enough_money ->
        :not_enough_money
    end
  end
end
