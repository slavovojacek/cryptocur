defmodule CryptocurTest do
  use ExUnit.Case
  doctest Cryptocur

  test "greets the world" do
    assert Cryptocur.hello() == :world
  end
end
