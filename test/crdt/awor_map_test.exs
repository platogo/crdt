defmodule CRDT.AWORMapTest do
  use ExUnit.Case
  doctest CRDT.AWORMap
  doctest CRDT.CRDT.AWORMap
  doctest CRDT.Access.CRDT.AWORMap

  describe "put/4" do
    test "raises if value is not a CRDT" do
      assert_raise Protocol.UndefinedError, fn ->
        CRDT.AWORMap.new() |> CRDT.AWORMap.put(:a, :key, "value")
      end
    end
  end

  describe "KeyError on missing keys" do
    test "fetch!/2 raises on missing key" do
      assert_raise KeyError, fn ->
        CRDT.AWORMap.new() |> CRDT.AWORMap.fetch!(:key)
      end
    end

    test "update!/4 raises on missing key" do
      assert_raise KeyError, fn ->
        CRDT.AWORMap.new()
        |> CRDT.AWORMap.update!(:a, :key, &CRDT.GCounter.increment(&1, :a))
      end
    end

    test "Access.get_in/2 raises on missing key" do
      assert_raise KeyError, fn ->
        CRDT.AWORMap.new() |> CRDT.Access.get_in([:key_a, :key_b])
      end
    end

    test "Access.put_in/4 raises on missing key" do
      assert_raise KeyError, fn ->
        CRDT.AWORMap.new()
        |> CRDT.Access.put_in(:actor, [:key_a, :key_b], CRDT.GCounter.new(a: 1, b: 2))
      end
    end

    test "Access.update_in/4 raises on missing key" do
      assert_raise KeyError, fn ->
        CRDT.AWORMap.new()
        |> CRDT.Access.update_in(:actor, [:key_a, :key_b], &CRDT.GCounter.increment(&1, :a))
      end
    end

    test "Access.update_in/4 raises on missing nested key" do
      assert_raise KeyError, fn ->
        CRDT.AWORMap.new()
        |> CRDT.AWORMap.put(:actor, :key_a, CRDT.AWORMap.new())
        |> CRDT.Access.update_in(:actor, [:key_a, :key_b], &CRDT.GCounter.increment(&1, :a))
      end
    end
  end
end
