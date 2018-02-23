defmodule CryptocurTest.Block do
  use ExUnit.Case
  doctest Cryptocur.Block

  test "hash matches difficulty 1 when starting with <<0>>" do
    hash = <<0, 147, 12, 1>>
    res = Cryptocur.Block.hash_matches_difficulty(hash, 1)
    assert res == true
  end

  test "hash does not match difficulty 2 when starting with <<0, 1>>" do
    hash = <<0, 1, 2, 3>>
    res = Cryptocur.Block.hash_matches_difficulty(hash, 2)
    assert res == false
  end

  test "finds a block matching difficulty 1" do
    index = 42
    previous_hash = <<0, 1, 2, 3>>
    timestamp = System.system_time(:second)
    data = "Hello, World!"
    difficulty = 1
    nonce = 0

    block = Cryptocur.Block.find(index, previous_hash, timestamp, data, difficulty, nonce)

    prefix = String.duplicate(<<0>>, difficulty)
    <<^prefix::binary-size(difficulty), rest::binary>> = block.hash

    assert is_binary(rest) and String.length(rest) > 0 == true
    assert block.index == index
    assert block.previous_hash == previous_hash
    assert block.timestamp == timestamp
    assert block.data == data
    assert block.difficulty == difficulty
    assert block.nonce > 0
  end

  test "finds a block matching difficulty 0" do
    difficulty = 0
    nonce = 0

    block =
      Cryptocur.Block.find(0, <<0, 1, 2, 3>>, 1_519_388_846, "Hello, World!", difficulty, nonce)

    prefix = String.duplicate(<<0>>, difficulty)
    <<^prefix::binary-size(difficulty), rest::binary>> = block.hash

    assert is_binary(rest) and String.length(rest) > 0 == true
    assert block.nonce == 0
  end
end
