defmodule ExBanking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    init_user_server_store()

    children = [
      {Registry, keys: :unique, name: ExBanking.UserRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init_user_server_store do
    :ets.new(ExBanking.User, [:public, :named_table])
  end
end
