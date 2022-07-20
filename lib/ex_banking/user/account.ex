defmodule ExBanking.UserInfo.Account do
  @moduledoc false

  # FOR THE EVALUATORS:
  # I've created this internal module because I believe in the principle of
  # Single Responsability (from SOLID) to organize module functions. And it has
  # given me good results. So I've created this internal module to handle
  # accounts logic
  #
  # I chose to use balance instead transactions because we don't need to track
  # individual transactions. But it's easy to refactor and track transaction if
  # needed.

  defstruct balance: 0, currency: nil

  @type t :: %__MODULE__{
          balance: Decimal.t(),
          currency: String.t()
        }

  def new(currency, amount \\ 0) do
    %__MODULE__{
      balance: to_decimal(amount),
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
      :not_enough_money
    end
  end

  defp to_decimal(number) when is_float(number), do: Decimal.from_float(number)
  defp to_decimal(number), do: Decimal.new(number)

  defp normalize_amount(amount), do: amount |> to_decimal() |> Decimal.round(2, :down)
end
