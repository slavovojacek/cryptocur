defmodule Cryptocur.Blockchain do
  alias Cryptocur.Block

  use GenServer

  @name :blockchain

  defmodule State do
    defstruct blockchain: []
  end

  def start_link(_arg) do
    IO.puts("Starting the Blockchain Server ...")
    GenServer.start_link(__MODULE__, %State{}, name: @name)
  end

  def init(state) do
    genesis_block = get_genesis_block()
    new_state = %{state | blockchain: [genesis_block]}
    {:ok, new_state}
  end

  defp get_genesis_block() do
    block = %Block{}

    timestamp = 1_519_294_957
    data = "Genesis Block"
    hash = Block.calc_hash(block.index, block.previous_hash, timestamp, data)

    %{block | hash: hash, timestamp: timestamp, data: data}
  end

  defp validate_blockchain(blockchain) when is_list(blockchain) do
    [genesis_block | rest] = blockchain

    %Block{hash: hash} = genesis_block
    %Block{hash: genuine_hash} = get_genesis_block()

    is_valid_genesis_block = hash === genuine_hash

    # TODO Eventually use gen stage and flow
    is_valid_rest =
      rest
      |> Enum.reverse()
      |> Enum.with_index()
      |> Enum.all?(fn {block, index} ->
        Block.is_valid_block(block, Enum.at(blockchain, index - 1))
      end)

    is_valid_genesis_block and is_valid_rest
  end

  # Server Methods

  def get_blockchain() do
    GenServer.call(@name, :get_blockchain)
  end

  def generate_block(data) do
    GenServer.call(@name, {:generate_block, data})
  end

  def get_latest_block() do
    GenServer.call(@name, :get_latest_block)
  end

  def is_valid_blockchain() do
    GenServer.call(@name, :is_valid_blockchain)
  end

  def handle_call(:get_blockchain, _from, %State{blockchain: blockchain} = state) do
    {:reply, blockchain, state}
  end

  def handle_call({:generate_block, data}, _from, %State{blockchain: blockchain} = state) do
    latest_block = blockchain |> List.last()
    block = Block.generate(latest_block, data)
    new_state = %{state | blockchain: blockchain ++ [block]}
    {:reply, block, new_state}
  end

  def handle_call(:get_latest_block, _from, %State{blockchain: blockchain} = state) do
    latest_block = blockchain |> List.last()
    {:reply, latest_block, state}
  end

  def handle_call(:is_valid_blockchain, _from, %State{blockchain: blockchain} = state) do
    res = validate_blockchain(blockchain)
    {:reply, res, state}
  end
end
