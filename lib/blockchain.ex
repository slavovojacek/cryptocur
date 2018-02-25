defmodule Cryptocur.Blockchain do
  alias Cryptocur.Block

  use GenServer

  @name :blockchain
  @block_generation_interval 10
  @difficulty_adjustment_interval 10

  defmodule State do
    defstruct blockchain: [], unspent_transaction_outputs: []
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
    hash = Block.calc_hash(block.index, block.previous_hash, timestamp, data, 0, 0)

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
      |> Enum.all?(fn block ->
        Block.is_valid_block(block, Enum.at(blockchain, block.index - 1))
      end)

    is_valid_genesis_block and is_valid_rest
  end

  defp get_difficulty(%Block{index: 0} = latest_block, _blockchain) do
    latest_block.difficulty
  end

  defp get_difficulty(%Block{index: index} = latest_block, blockchain) do
    case rem(index, @difficulty_adjustment_interval) do
      0 -> get_adjusted_difficulty(latest_block, blockchain)
      _ -> latest_block.difficulty
    end
  end

  defp get_adjusted_difficulty(latest_block, blockchain) do
    previous_adjustment_block =
      Enum.at(blockchain, length(blockchain) - @difficulty_adjustment_interval)

    time_expected = @block_generation_interval * @difficulty_adjustment_interval
    time_taken = latest_block.timestamp - previous_adjustment_block.timestamp

    cond do
      time_taken < time_expected / 2 -> previous_adjustment_block.difficulty + 1
      time_taken > time_expected * 2 -> previous_adjustment_block.difficulty - 1
      true -> previous_adjustment_block.difficulty
    end
  end

  defp get_accumulated_difficulty(blockchain) do
    blockchain
    |> Enum.map(fn block -> :math.pow(2, block.difficulty) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
    |> round
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

  def replace_blockchain(blocks) do
    GenServer.call(@name, {:replace_blockchain, blocks})
  end

  # Handling calls, casts, and infos

  def handle_call(:get_blockchain, _from, %State{blockchain: blockchain} = state) do
    {:reply, blockchain, state}
  end

  def handle_call({:generate_block, data}, _from, %State{blockchain: blockchain} = state) do
    latest_block = blockchain |> List.last()
    difficulty = get_difficulty(latest_block, blockchain)
    # Not sure async/await adds much value here..
    block = Task.await(Block.generate(latest_block, data, difficulty))
    IO.puts("Block #{inspect(block)} generated!")
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

  def handle_call({:replace_blockchain, blocks}, _from, %State{blockchain: blockchain} = state) do
    case validate_blockchain(blocks) and
           get_accumulated_difficulty(blocks) > get_accumulated_difficulty(blockchain) do
      true ->
        IO.puts(
          "New blockchain is valid and has greater difficulty. Replacing current blockchain ..."
        )

        new_state = %{state | blockchain: blocks}
        {:reply, :ok, new_state}

      _ ->
        {:reply, :err, state}
    end
  end
end
