defmodule TrServerApp do
  use Application

  def start(_type, _args) do
    case TrServer.Supervisor.start_link() do
      {:ok, pid} ->
        {:ok, pid}
      other ->
        {:error, other}
    end
  end
end
