defmodule Cryptocur.Block do
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

  def calc_hash(index, previous_hash, timestamp, data, difficulty, nonce)
      when is_integer(index) and is_binary(previous_hash) and is_integer(timestamp) and
             is_binary(data) and is_integer(difficulty) and is_integer(nonce) do
    index = Integer.to_string(index)
    timestamp = Integer.to_string(timestamp)
    difficulty = Integer.to_string(difficulty)
    nonce = Integer.to_string(nonce)

    payload = index <> previous_hash <> timestamp <> data <> difficulty <> nonce

    # |> Base.encode16()
    :crypto.hash(:sha, payload)
  end

  def calc_hash(index, nil, timestamp, data, difficulty, nonce)
      when is_integer(index) and is_integer(timestamp) and is_binary(data) and
             is_integer(difficulty) and is_integer(nonce) do
    index = Integer.to_string(index)
    timestamp = Integer.to_string(timestamp)
    difficulty = Integer.to_string(difficulty)
    nonce = Integer.to_string(nonce)

    payload = index <> timestamp <> data <> difficulty <> nonce

    # |> Base.encode16()
    :crypto.hash(:sha, payload)
  end

  def generate(%Cryptocur.Block{index: previous_index, hash: previous_hash}, data, difficulty)
      when is_binary(data) do
    index = previous_index + 1
    timestamp = get_current_timestamp()

    Task.async(__MODULE__, :find, [index, previous_hash, timestamp, data, difficulty, 0])
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

  def hash_matches_difficulty(hash, difficulty) when is_binary(hash) and is_integer(difficulty) do
    prefix = String.duplicate(<<0>>, difficulty)

    case hash do
      <<^prefix::binary-size(difficulty), _rest::binary>> -> true
      _ -> false
    end
  end

  def find(index, previous_hash, timestamp, data, difficulty, nonce)
      when is_integer(index) and is_binary(previous_hash) and is_integer(timestamp) and
             is_binary(data) and is_integer(difficulty) and is_integer(nonce) do
    hash = calc_hash(index, previous_hash, timestamp, data, difficulty, nonce)

    # IO.puts("Trying #{inspect(hash)}")

    case hash_matches_difficulty(hash, difficulty) do
      true ->
        %Cryptocur.Block{
          index: index,
          hash: hash,
          previous_hash: previous_hash,
          timestamp: timestamp,
          data: data,
          difficulty: difficulty,
          nonce: nonce
        }

      _ ->
        find(index, previous_hash, timestamp, data, difficulty, nonce + 1)
    end
  end
end
