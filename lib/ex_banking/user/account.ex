defmodule ExBanking.User.Account do
  @moduledoc false

  defstruct balance: 0, currency: nil

  @type t :: %__MODULE__{
          balance: pos_integer(),
          currency: String.t()
        }

  def new(currency) do
    %__MODULE__{
      balance: Decimal.new(0),
      currency: String.upcase(currency)
    }
  end

  def balance(%__MODULE__{balance: balance}), do: Decimal.to_float(balance)

  def deposit(%__MODULE__{balance: balance} = account, amount) do
    new_balance = Decimal.add(balance, normalize_amount(amount))

    %{account | balance: new_balance}
  end

  def withdraw(%__MODULE__{balance: balance} = account, amount) do
    new_balance = Decimal.sub(balance, normalize_amount(amount))

    if Decimal.positive?(new_balance) do
      %{account | balance: new_balance}
    else
      :insuficient_funds
    end
  end

  defp to_decimal(number) when is_float(number), do: Decimal.from_float(number)
  defp to_decimal(number), do: Decimal.new(number)

  defp normalize_amount(amount), do: amount |> to_decimal() |> Decimal.round(2, :down)
end
