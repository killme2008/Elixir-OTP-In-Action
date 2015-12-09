defmodule TrServer.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      worker(TrServer, [], restart: :permanent, shutdown: 2000)
    ]
    supervise(children, strategy: :one_for_one, max_restarts: 0, max_seconds: 1)
  end

end
