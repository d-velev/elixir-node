defmodule Aetestframework.Worker do
  @moduledoc """
  Module for multi node sync test.
  """

  require Logger
  use GenServer

  defstruct port_id: nil, node_port: nil, sync_port: nil
  use ExConstructor

  @default_timeout 5_000

  # Client API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def state, do: GenServer.call(__MODULE__, :state)

  @doc """
  Creates an elixir node
  """
  @spec new_node(atom(), non_neg_integer()) :: :ok
  def new_node(node_name, iex_num) do
    GenServer.call(__MODULE__, {:new_node, node_name, iex_num}, 10_000)
  end

  @doc """
  Post a command to a specific node.
  Used to send command that will return some response and we need to
  handle it. Like getting the top header hash
  """
  @spec get(String.t(), atom(), atom(), non_neg_integer()) :: any()
  def get(cmd, match_by, node, timeout \\ @default_timeout) do
    GenServer.call(__MODULE__, {:get, node, match_by, cmd}, timeout)
  end

  @doc """
  Post some commands to a specific node.
  Used to send commands that don't need a response.
  Like mining a block
  """
  @spec post(String.t(), atom(), atom(), non_neg_integer()) :: :ok
  def post(cmd, match_by, node, timeout \\ @default_timeout) do
    GenServer.call(__MODULE__, {:post, node, match_by, cmd}, timeout)
  end

  @doc """
  Killing all the processes and closing all of the ports of the nodes
  """
  @spec delete_all_nodes() :: :ok
  def delete_all_nodes do
    GenServer.call(__MODULE__, :delete_nodes)
  end

  @doc """
  Call a GenServer API function with specific delay
  """
  @spec call_with_delay(String.t(), reference(), atom(), atom(), non_neg_integer()) :: any
  def call_with_delay(cmd, fun, match_by, node, delay) do
    :timer.sleep(delay)
    new_timeout = @default_timeout + delay
    fun.(cmd, match_by, node, new_timeout)
  end

  # Server side

  def init(state) do
    {:ok, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:new_node, node_name, iex_num}, _from, state) do
    cond do
      Map.has_key?(state, node_name) ->
        {:reply, :already_exists, state}

      busy_port?("300#{iex_num}") || busy_port?("400#{iex_num}") ->
        {:reply, :busy_port, state}

      true ->
        # Running the new elixir-node using Port
        path = String.replace(System.cwd(), ~r/(?<=elixir-node).*$/, "")
        port_id = Port.open({:spawn, "make iex-node NODE_NUMBER=#{iex_num}"}, [:binary, cd: path])
        port = String.to_integer("400#{iex_num}")
        sync_port = String.to_integer("300#{iex_num}")

        expected_result = fn _ -> :node_started end
        :node_started = receive_result("Interactive Elixir", expected_result)

        new_node = __MODULE__.new(%{port_id: port_id, node_port: port, sync_port: sync_port})
        new_state = Map.put(state, node_name, new_node)

        {:reply, :ok, new_state}
    end
  end

  def handle_call({:get, node, match_by, cmd}, _from, state) do
    %{port_id: port_id} = Map.get(state, node)
    command = "{:#{match_by}," <> cmd <> "}\n"
    Port.command(port_id, command)
    result = receive_result(":#{match_by}", &__MODULE__.process_result/1)
    {:reply, result, state}
  end

  def handle_call({:post, node, match_by, cmd}, _from, state) do
    %{port_id: port_id} = Map.get(state, node)
    command = "{:#{match_by}," <> cmd <> "}\n"
    Port.command(port_id, command)
    expected_result = fn _ -> :ok end
    :ok = receive_result(":#{match_by}", expected_result)
    {:reply, :ok, state}
  end

  def handle_call(:delete_nodes, _from, state) do
    Enum.each(state, fn {_node, %{port_id: port_id, node_port: port}} ->
      Port.command(port_id, ":erlang.halt()\n")
      Port.close(port_id)
      path = String.replace(System.cwd(), ~r/(?<=elixir-node).*$/, "") <> "/apps/aecore/priv/"
      File.rm_rf(path <> "aewallet_#{port}")
      File.rm_rf(path <> "peerkeys_#{port}")
      File.rm_rf(path <> "rox_db_#{port}")
    end)

    {:reply, :ok, %{}}
  end

  def handle_info(_data, state) do
    {:noreply, state}
  end

  def process_result(result) do
    filtered_result = String.replace(result, "\n", "")
    matched_result = Regex.run(~r/\"(.*?)\"/, filtered_result)
    base_decoded = Base.decode32!(List.last(matched_result))
    :erlang.binary_to_term(base_decoded)
  end

  defp receive_result(key, fun) do
    receive do
      {_port, {:data, result}} ->
        if result =~ key do
          fun.(result)
        else
          receive_result(key, fun)
        end
    end
  end

  @doc """
  Checking if the port is busy
  """
  def busy_port?(port) do
    :os.cmd('lsof -i -P -n | grep -w #{port}') != []
  end
end
