defmodule SimpleCache.EventLogger do
  use GenEvent
  require Logger

  def add_handler() do
    SimpleCache.Event.add_handler(__MODULE__, [])
  end

  def remove_handler() do
    SimpleCache.Event.remove_handler(__MODULE__, [])
  end

  def handle_event(event, parent) do
    Logger.info "Event: #{inspect(event)}"
    {:ok, parent}
  end
end
