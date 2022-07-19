defmodule ExBanking.UserServer do
  use GenServer

  alias ExBanking.User

  def start_link(name) do
    case GenServer.start_link(__MODULE__, [name], name: via_tuple(name)) do
      {:ok, _pid} -> {:ok, name}
      {:error, {:already_started, _pid}} -> {:error, :already_started}
      error -> error
    end
  end

  defp via_tuple(name) do
    {:via, Registry, {ExBanking.UserRegistry, name}}
  end

  def balance(name, currency) do
    GenServer.call(via_tuple(name), {:balance, currency})
  end

  @impl true
  def init(name) do
    {:ok, User.new(name)}
  end

  @impl true
  def handle_call({:balance, currency}, _from, user) do
    {:reply, User.balance(user, currency), user}
  end
end
