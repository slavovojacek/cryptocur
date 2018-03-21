defmodule Cryptocur.ProofOfWork do
  def calc_hash(index, nil, timestamp, data, difficulty, nonce)
      when is_integer(index) and is_integer(timestamp) and is_binary(data) and
             is_integer(difficulty) and is_integer(nonce) do
    index = Integer.to_string(index)
    timestamp = Integer.to_string(timestamp)
    difficulty = Integer.to_string(difficulty)
    nonce = Integer.to_string(nonce)

    payload = index <> timestamp <> data <> difficulty <> nonce

    :crypto.hash(:sha, payload)
  end

  def calc_hash(index, previous_hash, timestamp, data, difficulty, nonce)
      when is_integer(index) and is_binary(previous_hash) and is_integer(timestamp) and
             is_binary(data) and is_integer(difficulty) and is_integer(nonce) do
    index = Integer.to_string(index)
    timestamp = Integer.to_string(timestamp)
    difficulty = Integer.to_string(difficulty)
    nonce = Integer.to_string(nonce)

    payload = index <> previous_hash <> timestamp <> data <> difficulty <> nonce

    :crypto.hash(:sha, payload)
  end

  def hash_matches_difficulty(hash, difficulty) when is_binary(hash) and is_integer(difficulty) do
    prefix = String.duplicate(<<0>>, difficulty)

    case hash do
      <<^prefix::binary-size(difficulty), _rest::binary>> -> true
      _ -> false
    end
  end

  def find(index, previous_hash, timestamp, data, 0, nonce)
      when is_integer(index) and is_binary(previous_hash) and is_integer(timestamp) and
             is_binary(data) and is_integer(nonce) do
    hash = calc_hash(index, previous_hash, timestamp, data, 0, nonce)
    {hash, nonce}
  end

  def find(index, previous_hash, timestamp, data, difficulty, nonce)
      when is_integer(index) and is_binary(previous_hash) and is_integer(timestamp) and
             is_binary(data) and is_integer(difficulty) and is_integer(nonce) do
    hash = calc_hash(index, previous_hash, timestamp, data, difficulty, nonce)

    case hash_matches_difficulty(hash, difficulty) do
      true -> {hash, nonce}
      _ -> find(index, previous_hash, timestamp, data, difficulty, nonce + 1)
    end
  end

  # def get_hash_stream(index, previous_hash, timestamp, data, difficulty) do
  #   [fn nonce -> calc_hash(index, previous_hash, timestamp, data, difficulty, nonce) end]
  #   |> Stream.cycle()
  #   |> Stream.with_index()
  #   |> Task.async_stream(fn {f, i} -> f.(i) end)
  #   |> Stream.map(fn
  #     {:ok, res} -> res
  #     _ -> nil
  #   end)
  #   |> Stream.reject(fn res -> res == nil end)
  #   |> Stream.reject(fn hash -> !hash_matches_difficulty(hash, difficulty) end)
  # end
end
