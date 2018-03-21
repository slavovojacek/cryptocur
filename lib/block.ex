defmodule Cryptocur.Block do
  import Cryptocur.ProofOfWork, only: [find: 6, calc_hash: 6]

  defstruct index: 0,
            hash: nil,
            previous_hash: nil,
            timestamp: System.system_time(:second),
            data: nil,
            difficulty: 0,
            nonce: 0

  defp get_current_timestamp() do
    System.system_time(:second)
  end

  def generate(%Cryptocur.Block{index: previous_index, hash: previous_hash}, data, difficulty)
      when is_binary(data) do
    index = previous_index + 1
    timestamp = get_current_timestamp()

    {hash, nonce} = find(index, previous_hash, timestamp, data, difficulty, 0)

    %Cryptocur.Block{
      index: index,
      hash: hash,
      previous_hash: previous_hash,
      timestamp: timestamp,
      data: data,
      difficulty: difficulty,
      nonce: nonce
    }
  end

  def is_valid_block(
        %Cryptocur.Block{
          index: index,
          hash: hash,
          previous_hash: previous_hash,
          timestamp: timestamp,
          data: data,
          difficulty: difficulty,
          nonce: nonce
        } = block,
        %Cryptocur.Block{} = previous_block
      )
      when is_integer(index) and is_binary(hash) and is_binary(previous_hash) and
             is_integer(timestamp) and is_binary(data) and is_integer(difficulty) and
             is_integer(nonce) do
    index_valid = previous_block.index + 1 === index
    prev_hash_valid = previous_block.hash === previous_hash
    hash_valid = calc_hash(index, previous_hash, timestamp, data, difficulty, nonce) === hash
    is_valid_timestamp = is_valid_timestamp(block, previous_block)

    unless index_valid do
      IO.puts("Block #{inspect(block)} has an invalid index")
    end

    unless prev_hash_valid do
      IO.puts("Block #{inspect(block)} has an invalid previous hash")
    end

    unless hash_valid do
      IO.puts("Block #{inspect(block)} has an invalid hash")
    end

    unless is_valid_timestamp do
      IO.puts("Block #{inspect(block)} has an invalid timestamp")
    end

    index_valid and prev_hash_valid and hash_valid && is_valid_timestamp
  end

  def is_valid_timestamp(%Cryptocur.Block{timestamp: timestamp}, %Cryptocur.Block{
        timestamp: previous_timestamp
      }) do
    previous_timestamp - 60 < timestamp and timestamp - 60 < get_current_timestamp()
  end
end
