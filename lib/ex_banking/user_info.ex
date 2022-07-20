defmodule ExBanking.UserInfo do
  @moduledoc false

  defstruct name: nil, accounts: %{}

  alias ExBanking.UserInfo.Account

  @type t :: %__MODULE__{
          name: String.t(),
          accounts: %{String.t() => Account.t()}
        }

  @spec new(String.t()) :: t()
  def new(name) do
    %__MODULE__{name: name}
  end

  @spec balance(t(), String.t()) :: float
  def balance(%__MODULE__{accounts: accounts}, currency) do
    accounts
    |> Map.get(currency, Account.new(currency))
    |> Account.balance()
  end

  @spec deposit(t(), number, String.t()) :: t()
  def deposit(%__MODULE__{accounts: accounts} = user, amount, currency) do
    accounts =
      Map.update(
        accounts,
        currency,
        Account.new(currency, amount),
        &Account.deposit(&1, amount)
      )

    %{user | accounts: accounts}
  end

  @spec withdraw(t(), number, String.t()) :: :not_enough_money | t()
  def withdraw(%__MODULE__{accounts: accounts} = user, amount, currency) do
    account = Map.get(accounts, currency, Account.new(currency))

    case Account.withdraw(account, amount) do
      %Account{} = account ->
        %{user | accounts: Map.put(accounts, currency, account)}

      :not_enough_money ->
        :not_enough_money
    end
  end
end
