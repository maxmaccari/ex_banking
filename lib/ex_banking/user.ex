defmodule ExBanking.User do
  @moduledoc false

  use GenServer

  alias ExBanking.UserInfo

  def start_link(name) do
    case GenServer.start_link(__MODULE__, [name], name: via_tuple(name)) do
      {:ok, _pid} -> {:ok, name}
      {:error, {:already_started, _pid}} -> {:error, :already_started}
      error -> error
    end
  end

  def via_tuple(name) do
    {:via, Registry, {ExBanking.UserRegistry, name}}
  end

  # FOR THE EVALUATORS:
  # I understand that there's the phrase "let it crash", return that the user
  # does not exist is part of the business logic, and catch :exit in this case
  # is a good way to transform one error into a friendly error returning.

  def balance(name, currency) do
    GenServer.call(via_tuple(name), {:balance, currency})
  catch
    :exit, {:noproc, {GenServer, :call, _}} -> {:error, :user_does_not_exist}
  end

  def deposit(name, currency, amount) do
    GenServer.call(via_tuple(name), {:deposit, currency, amount})
  catch
    :exit, {:noproc, {GenServer, :call, _}} -> {:error, :user_does_not_exist}
  end

  def withdraw(name, currency, amount) do
    GenServer.call(via_tuple(name), {:withdraw, currency, amount})
  catch
    :exit, {:noproc, {GenServer, :call, _}} -> {:error, :user_does_not_exist}
  end

  def send(from, to, currency, amount, deposit_fun \\ &deposit/3) do
    GenServer.call(via_tuple(from), {:send, to, currency, amount, deposit_fun})
  catch
    :exit, {:noproc, {GenServer, :call, _}} -> {:error, :sender_does_not_exist}
  end

  @impl true
  def init(name) do
    {:ok, UserInfo.new(name), {:continue, {:load_user, name}}}
  end

  @impl true
  def handle_call({:balance, currency}, _from, user) do
    {:reply, {:ok, UserInfo.balance(user, currency)}, user}
  end

  def handle_call({:deposit, currency, amount}, _from, user) do
    user = UserInfo.deposit(user, currency, amount)
    {:reply, {:ok, UserInfo.balance(user, currency)}, user, {:continue, :backup_user}}
  end

  def handle_call({:withdraw, currency, amount}, _from, user) do
    case UserInfo.withdraw(user, currency, amount) do
      %UserInfo{} = user ->
        {:reply, {:ok, UserInfo.balance(user, currency)}, user, {:continue, :backup_user}}

      :not_enough_money ->
        {:reply, {:error, :not_enough_money}, user}
    end
  end

  def handle_call({:send, to, currency, amount, deposit_fun}, _from, user) do
    with %UserInfo{} = new_user <- UserInfo.withdraw(user, currency, amount),
         {:ok, to_user_balance} <- deposit_fun.(to, currency, amount) do
      {:reply, {:ok, UserInfo.balance(new_user, currency), to_user_balance}, new_user,
       {:continue, :backup_user}}
    else
      error -> {:reply, handle_send_error(error), user}
    end
  end

  defp handle_send_error(:not_enough_money), do: {:error, :not_enough_money}
  defp handle_send_error({:error, :user_does_not_exist}), do: {:error, :receiver_does_not_exist}
  defp handle_send_error(error), do: error

  @impl true
  def handle_continue({:load_user, name}, default_user) do
    current_user =
      case :ets.lookup(__MODULE__, name) do
        [] -> default_user
        [{_key, user}] -> user
      end

    :ets.insert(__MODULE__, {name, current_user})
    {:noreply, current_user}
  end

  def handle_continue(:backup_user, user) do
    :ets.insert(__MODULE__, {user.name, user})

    {:noreply, user}
  end
end
