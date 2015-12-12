defmodule ResourceDiscovery do
  use GenServer

  @server __MODULE__

  defmodule State do
	  defstruct target_resource_types: [], local_resource_tuples: HashDict.new,
              found_resource_tuples: HashDict.new
  end


  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_target_resouce_type(type) do
    GenServer.cast(@server, {:add_target_resource_type, type})
  end

  def add_local_resource(type, instance) do
    GenServer.cast(@server, {:add_local_resource, {type, instance}})
  end

  def fetch_resources(type) do
    GenServer.call(@server, {:fetch_resources, type})
  end

  def trade_resources() do
    GenServer.cast(@server, :trade_resources)
  end

  # Server callbacks
  def init(:ok) do
    {:ok, %State{}}
  end

  def handle_call({:fetch_resources, type}, _from, state) do
    {:reply, Dict.fetch(state.found_resource_tuples, type), state}
  end

  def handle_cast({:add_target_resource_type, type}, state) do
    target_types = state.target_resource_types
    new_types = [type | List.delete(target_types, type)]
    {:noreply, %{state | target_resource_types: new_types}}
  end

  def handle_cast({:add_local_resource, {type, instance}}, state) do
    local_tuples = state.local_resource_tuples
    new_tuples = add_resource(type, instance, local_tuples)
    {:noreply, %{state | local_resource_tuples: new_tuples}}
  end

  def handle_cast(:trade_resources, state) do
    resource_tuples = state.local_resource_tuples
    all_nodes = [Node.self | Node.list()]
    all_nodes |> Enum.each(fn node ->
      GenServer.cast({@server, node}, {:trade_resources,
                                       {Node.self, resource_tuples}})
    end)
    {:noreply, state}
  end

  def handle_cast({:trade_resources, {reply_to, remotes}},
                  %State{local_resource_tuples: locals,
                         target_resource_types: target_types,
                         found_resource_tuples: old_found}=state) do
    filtered_resources = resources_for_types(target_types, remotes)
    new_found = add_resources(filtered_resources, old_found)
    case reply_to do
      :noreply ->
        :ok
      _ ->
        GenServer.cast({@server, reply_to},
                       {:trade_resources, {:noreply, locals}})
    end
    {:noreply, %{state | found_resource_tuples: new_found}}
  end

  defp resources_for_types(target_types, resources) do
    target_types
    |> Enum.reduce([], fn(type, acc) ->
      case Dict.fetch(resources, type) do
        {:ok, list} ->
          tuples = for instance <- list ,into: [],  do: {type, instance}
          tuples ++ acc
        :error ->
          acc
      end
    end)
  end

  defp add_resources([], resource_tuples) do
    resource_tuples
  end

  defp add_resources([{type, resource} | tail], resource_tuples) do
    add_resources(tail, add_resource(type, resource, resource_tuples))
  end

  defp add_resource(type, resource, tuples) do
    resources = Dict.get tuples, type, []
    Dict.put tuples, type, [resource | List.delete(resources, resource)]
  end

end
