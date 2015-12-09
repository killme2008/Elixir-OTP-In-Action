defmodule SimpleCache.Event do
  @server __MODULE__

  def start_link() do
    GenEvent.start_link(name: @server)
  end

  def add_handler(handler, args) do
    GenEvent.add_handler(@server, handler, args)
  end

  def remove_handler(handler, args) do
    GenEvent.remove_handler(@server, handler, args)
  end

  def lookup(key) do
    GenEvent.notify(@server, {:lookup, key})
  end

  def create(key, value) do
    GenEvent.notify(@server, {:create, {key, value}})
  end

  def replace(key, value) do
    GenEvent.notify(@server, {:replace, {key, value}})
  end

  def delete(key) do
    GenEvent.notify(@server, {:delete, key})
  end
end
