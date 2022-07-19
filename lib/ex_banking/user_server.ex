defmodule ExBanking.UserServer do
  use GenServer

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

  @impl true
  def init(name) do
    {:ok, name}
  end
end
