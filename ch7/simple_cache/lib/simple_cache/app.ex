defmodule SimpleCache.App do
  use Application
  def start(_type, _args) do
    SimpleCache.Store.init()
    case SimpleCache.Supervisor.start_link do
      {:ok, pid} ->
        {:ok, pid}
      other ->
        {:error, other}
    end
  end

  def stop(_state) do
    :ok
  end
end
