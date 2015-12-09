defmodule SimpleCache.Supervisor do
  use Supervisor
  @server __MODULE__

  def start_link do
    Supervisor.start_link(@server, :ok, name: @server)
  end

  def init(:ok) do
    children = [
      worker(SimpleCache.Event, [],
             restart: :permanent,
             shutdown: 2000),
      supervisor(SimpleCache.ElementSupervisor, [],
             restart: :permanent,
             shutdown: 2000)
    ]
    supervise(children, strategy: :one_for_one, max_restarts: 4,
              max_seconds: 3600)
  end
end
