defmodule ExBanking.User.Account do
  @moduledoc false

  defstruct balance: 0, currency: nil

  @type t :: %__MODULE__{
          balance: pos_integer(),
          currency: String.t()
        }

  def new(currency) do
    %__MODULE__{
      balance: 0,
      currency: String.upcase(currency)
    }
  end

  def balance(%__MODULE__{balance: balance}), do: balance

  def deposit(%__MODULE__{balance: balance} = account, amount) do
    %{account | balance: balance + amount}
  end

  def withdraw(%__MODULE__{balance: balance}, amount)
      when amount > balance,
      do: :insuficient_funds

  def withdraw(%__MODULE__{balance: balance} = account, amount) do
    %{account | balance: balance - amount}
  end
end
