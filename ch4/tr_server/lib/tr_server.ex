defmodule TrServer do
  @module_doc """
  https://github.com/erlware/Erlang-and-OTP-in-Action-Source/blob/master/chapter_03/tr_server.erl
  RPC over TCP server. This module defines a server process that
  listens for incoming TCP connections and allows the user to
  execute RPC commands via that TCP stream.
  """
  use GenServer
  use Application
  require Logger
  @server __MODULE__
  @default_port 1055

  defmodule State do
	  defstruct port: nil, lsock: nil, request_count: 0, binding: []
  end

  def start(_type,_args) do
    start_link()
  end

  def start_link(), do: start_link(@default_port)
  def start_link(port) do
    GenServer.start_link(@server, port, name: @server)
  end

  def get_count() do
    GenServer.call(@server, :get_count)
  end

  def init(port) do
    {:ok, lsock} = :gen_tcp.listen(port, [active: true])
    {:ok, %State{port: port, lsock: lsock}, 0}
  end

  def handle_info({:tcp, sock, data}, state) do
    new_binding = do_rpc(sock, data, state.binding)
    request_count = state.request_count + 1
    {:noreply, %{state | request_count: request_count, binding: new_binding}}
  end

  def handle_info(:timeout, state) do
    {:ok, _sock} = :gen_tcp.accept(state.lsock)
    {:noreply, state}
  end

  def do_rpc(sock, data, binding) do
    try do
      #{m, f, a} = split_out_mfa(data)
      #result = apply(m, f, a)
      {result, new_binding} = Code.eval_string(data, binding)
      :gen_tcp.send(sock, :io_lib.fwrite("~p~n", [result]))
      new_binding
    catch
      _, err ->
        :gen_tcp.send(sock, :io_lib.fwrite("~p~n", [err]))
        binding
    end
  end

  def split_out_mfa(data) do
    mfa = data |> List.to_string |> String.replace(~r/\r\n$/, "")
    case Regex.run(~r/(.*)\.(.*)\s*\((.*)\s*\)\s*$/, mfa) do
      [_, m, f, a] ->
        {resolve_m(m), String.to_atom(f), args_to_term(a)}
        _ ->
        nil
    end
  end

  def args_to_term(args) do
    {:ok, tokens, _line} = :erl_scan.string('[' ++ String.to_char_list(args) ++ '].', 1)
    {:ok, args} = :erl_parse.parse_term(tokens)
    args
  end

  def resolve_m(m) do
    if String.starts_with?(m, ":") do
      len = String.length(m)
      m |> String.slice(1, len-1) |> String.to_atom
    else
      String.to_atom("Elixir." <> m)
    end
  end

  def stop do
    GenServer.cast(@server, :stop)
  end

  def handle_call(:get_count, _from, state) do
    {:reply, state.request_count, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

end
