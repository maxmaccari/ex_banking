defmodule ExBanking.User do
  @moduledoc false

  use GenServer

  alias ExBanking.UserInfo

  def start_link(name) when is_binary(name) do
    case GenServer.start_link(__MODULE__, [name], name: via_tuple(name)) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  def start_link(_name), do: {:error, :wrong_arguments}

  def via_tuple(name) do
    {:via, Registry, {ExBanking.UserRegistry, name}}
  end

  def balance(name, currency) when is_binary(name) and is_binary(currency) do
    with :ok <- check_user(name),
         do: GenServer.call(via_tuple(name), {:balance, currency})
  end

  def balance(_name, _currency), do: {:error, :wrong_arguments}

  def deposit(name, amount, currency)
      when is_binary(name) and is_binary(currency) and is_number(amount) do
    with :ok <- check_user(name),
         do: GenServer.call(via_tuple(name), {:deposit, amount, currency})
  end

  def deposit(_name, _amount, _currency), do: {:error, :wrong_arguments}

  def withdraw(name, amount, currency)
      when is_binary(name) and is_binary(currency) and is_number(amount) do
    with :ok <- check_user(name),
         do: GenServer.call(via_tuple(name), {:withdraw, amount, currency})
  end

  def withdraw(_name, _amount, _currency), do: {:error, :wrong_arguments}

  def send(from, to, amount, currency, deposit_fun \\ &deposit/3)

  def send(from, to, amount, currency, deposit_fun)
      when is_binary(from) and is_binary(to) and is_binary(currency) and is_number(amount) do
    case check_user(from) do
      :ok -> GenServer.call(via_tuple(from), {:send, to, amount, currency, deposit_fun})
      {:error, :too_many_requests_to_user} -> {:error, :too_many_requests_to_sender}
      {:error, :user_does_not_exist} -> {:error, :sender_does_not_exist}
    end
  end

  def send(_from, _to, _amount, _currency, _fun), do: {:error, :wrong_arguments}

  @impl true
  def init(name) do
    {:ok, UserInfo.new(name), {:continue, {:load_user, name}}}
  end

  @impl true
  def handle_call({:balance, currency}, _from, user) do
    {:reply, {:ok, UserInfo.balance(user, currency)}, user}
  end

  def handle_call({:deposit, amount, currency}, _from, user) do
    user = UserInfo.deposit(user, amount, currency)
    backup_user(user)

    {:reply, {:ok, UserInfo.balance(user, currency)}, user}
  end

  def handle_call({:withdraw, amount, currency}, _from, user) do
    case UserInfo.withdraw(user, amount, currency) do
      %UserInfo{} = user ->
        backup_user(user)
        {:reply, {:ok, UserInfo.balance(user, currency)}, user}

      :not_enough_money ->
        {:reply, {:error, :not_enough_money}, user}
    end
  end

  def handle_call({:send, to, amount, currency, deposit_fun}, _from, user) do
    with %UserInfo{} = new_user <- UserInfo.withdraw(user, amount, currency),
         {:ok, to_user_balance} <- deposit_fun.(to, amount, currency) do
      backup_user(new_user)
      {:reply, {:ok, UserInfo.balance(new_user, currency), to_user_balance}, new_user}
    else
      error -> {:reply, handle_send_error(error), user}
    end
  end

  defp handle_send_error(:not_enough_money), do: {:error, :not_enough_money}
  defp handle_send_error({:error, :user_does_not_exist}), do: {:error, :receiver_does_not_exist}

  defp handle_send_error({:error, :too_many_requests_to_user}),
    do: {:error, :too_many_requests_to_receiver}

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

  defp backup_user(user) do
    :ets.insert(__MODULE__, {user.name, user})
  end

  defp check_user(name) do
    case name |> via_tuple() |> GenServer.whereis() do
      nil ->
        {:error, :user_does_not_exist}

      pid ->
        {:message_queue_len, len} = :erlang.process_info(pid, :message_queue_len)

        if len > 10, do: {:error, :too_many_requests_to_user}, else: :ok
    end
  end
end
