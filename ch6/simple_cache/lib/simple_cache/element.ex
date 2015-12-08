defmodule SimpleCache.Element do
  use GenServer

  @server __MODULE__
  @default_lease_time 60*60*24

  defmodule State do
    defstruct value: nil, lease_time: 0, start_time: 0
  end


  # Client API
  def start_link(value, lease_time) do
    GenServer.start_link(__MODULE__, [value, lease_time])
  end

  def create(value, lease_time) do
    SimpleCache.Supervisor.start_child(value, lease_time)
  end

  def create(value) do
    create(value, @default_lease_time)
  end

  def fetch(pid) do
    GenServer.call(pid, :fetch)
  end

  def replace(pid, value) do
    GenServer.cast(pid, {:replace, value})
  end

  def delete(pid) do
    GenServer.cast(pid, :delete)
  end

  # Server callbacks
  def init([value, lease_time]) do
    now = :calendar.local_time()
    start_time = :calendar.datetime_to_gregorian_seconds(now)
    {:ok, %State{value: value, lease_time: lease_time, start_time: start_time},
     time_left(start_time, lease_time)}
  end

  defp time_left(_start_time, :infinity) do
    :infinity
  end

  defp time_left(start_time, lease_time) do
    now = :calendar.local_time()
    current_time = :calendar.datetime_to_gregorian_seconds(now)
    time_elapsed = current_time - start_time
    case lease_time - time_elapsed do
                      time when time <=0 ->
                        0
                      time ->
                        time * 1000
    end
  end

  def handle_call(:fetch, _from, state) do
    {:reply, {:ok, state.value}, state,
     time_left(state.start_time, state.lease_time)}
  end

  def handle_cast(:delete, state) do
    {:stop, :normal, state}
  end

  def handle_cast({:replace, value}, state) do
    {:noreply, %{state | value: value},
     time_left(state.start_time, state.lease_time)}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, state) do
    SimpleCache.Store.delete(self())
    :ok
  end

end
