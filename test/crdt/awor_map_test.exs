defmodule CRDT.AWORMapTest do
  use ExUnit.Case
  doctest CRDT.AWORMap
  doctest CRDT.CRDT.AWORMap

  describe "put/4" do
    test "raises if value is not a CRDT" do
      assert_raise Protocol.UndefinedError, fn ->
        CRDT.AWORMap.new() |> CRDT.AWORMap.put(:a, :key, "value")
      end
    end
  end
end
