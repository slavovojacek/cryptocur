defmodule Sandbox do
  # alias Cryptocur.Block
  # alias Cryptocur.ProofOfWork

  # defp get_current_timestamp() do
  #   System.system_time(:second)
  # end

  # def find_recurse(difficulty) do
  #   timestamp = get_current_timestamp()

  #   1..2
  #     |> Enum.map(fn _i -> ProofOfWork.find(42, "previous_hash", timestamp, "data", difficulty, 0) end)
  # end

  # def find_stream(difficulty) do
  #   timestamp = get_current_timestamp()

  #   ProofOfWork.get_hash_stream(42, "previous_hash", timestamp, "data", difficulty)
  #     |> Enum.take(2)
  # end
end
