defmodule SimpleCache do
  def insert(key, value, lease_time) do
    case SimpleCache.Store.lookup(key) do
      {:ok, pid} ->
        SimpleCache.Element.replace(pid, value)
      {:error, _} ->
        {:ok, pid} = SimpleCache.Element.create(value, lease_time)
        SimpleCache.Store.insert(key, pid)
    end
  end

  def insert(key, value) do
    case SimpleCache.Store.lookup(key) do
      {:ok, pid} ->
        SimpleCache.Element.replace(pid, value)
      {:error, _} ->
        {:ok, pid} = SimpleCache.Element.create(value)
        SimpleCache.Store.insert(key, pid)
    end
  end

  def lookup(key) do
    try do
      {:ok, pid} = SimpleCache.Store.lookup(key)
      {:ok, value} = SimpleCache.Element.fetch(pid)
      {:ok, value}
    catch
      _class,_exception -> {:error, :not_found}
    end
  end

  def delete(key) do
    case SimpleCache.Store.lookup(key) do
      {:ok, pid} ->
        SimpleCache.Element.delete(pid)
      {:error, _} ->
        :ok
    end
  end
end
