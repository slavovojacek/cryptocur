defmodule Cryptocur.Block do
  defstruct index: 0,
            hash: nil,
            previous_hash: nil,
            timestamp: System.system_time(:second),
            data: nil

  def calc_hash(index, previous_hash, timestamp, data)
      when is_integer(index) and is_binary(previous_hash) and is_integer(timestamp) and
             is_binary(data) do
    index = Integer.to_string(index)
    timestamp = Integer.to_string(timestamp)

    payload = index <> previous_hash <> timestamp <> data

    :crypto.hash(:sha, payload) |> Base.encode16()
  end

  def calc_hash(index, nil, timestamp, data)
      when is_integer(index) and is_integer(timestamp) and is_binary(data) do
    index = Integer.to_string(index)
    timestamp = Integer.to_string(timestamp)

    payload = index <> timestamp <> data

    :crypto.hash(:sha, payload) |> Base.encode16()
  end

  def generate(%Cryptocur.Block{index: prev_index, hash: prev_hash}, data) when is_binary(data) do
    index = prev_index + 1
    timestamp = System.system_time(:second)
    hash = calc_hash(index, prev_hash, timestamp, data)

    %Cryptocur.Block{
      index: index,
      hash: hash,
      previous_hash: prev_hash,
      timestamp: timestamp,
      data: data
    }
  end

  def is_valid_block(
        %Cryptocur.Block{
          index: index,
          hash: hash,
          previous_hash: previous_hash,
          timestamp: timestamp,
          data: data
        },
        %Cryptocur.Block{} = prev_block
      )
      when is_integer(index) and is_binary(hash) and is_binary(previous_hash) and
             is_integer(timestamp) and is_binary(data) do
    index_valid = prev_block.index + 1 === index
    prev_hash_valid = prev_block.hash === previous_hash
    hash_valid = calc_hash(index, previous_hash, timestamp, data) === hash

    index_valid and prev_hash_valid and hash_valid
  end
end
