defmodule CRDT.AWORSetTest do
  use ExUnit.Case
  doctest CRDT.AWORSet
  doctest CRDT.CRDT.AWORSet

  describe "add-wins semantics" do
    test "concurrent add on one replica and remove on another — add should win" do
      # Both replicas start with the same state: elements 1 and 2 added
      common =
        CRDT.AWORSet.new()
        |> CRDT.AWORSet.add(:a, 1)
        |> CRDT.AWORSet.add(:b, 2)

      # Replica A: removes elements 1 and 2
      a =
        common
        |> CRDT.AWORSet.remove(1)
        |> CRDT.AWORSet.remove(2)

      # Replica B: concurrently adds elements 1 and 3
      b =
        common
        |> CRDT.AWORSet.add(:b, 1)
        |> CRDT.AWORSet.add(:b, 3)

      # Add should win over concurrent remove:
      # - Element 1: removed by A, but concurrently re-added by B → should survive (add wins)
      # - Element 2: removed by A, not re-added by B → should be gone
      # - Element 3: added by B → should be present
      merged = CRDT.merge(a, b) |> CRDT.value() |> Enum.sort()
      assert merged == [1, 3]

      # Should be commutative
      merged_reverse = CRDT.merge(b, a) |> CRDT.value() |> Enum.sort()
      assert merged_reverse == [1, 3]
    end

    test "both replicas remove the same element — stays removed" do
      common =
        CRDT.AWORSet.new()
        |> CRDT.AWORSet.add(:a, 1)
        |> CRDT.AWORSet.add(:b, 2)

      a = CRDT.AWORSet.remove(common, 1)
      b = CRDT.AWORSet.remove(common, 1)

      merged = CRDT.merge(a, b) |> CRDT.value() |> Enum.sort()
      assert merged == [2]
    end
  end

  describe "merge properties" do
    test "idempotent — merge(a, a) produces same value as a" do
      a =
        CRDT.AWORSet.new()
        |> CRDT.AWORSet.add(:a, 1)
        |> CRDT.AWORSet.add(:a, 2)
        |> CRDT.AWORSet.remove(1)

      assert CRDT.merge(a, a) |> CRDT.value() |> Enum.sort() ==
               a |> CRDT.value() |> Enum.sort()
    end

    test "associative — merge(merge(a, b), c) == merge(a, merge(b, c))" do
      a = CRDT.AWORSet.new() |> CRDT.AWORSet.add(:a, 1)
      b = CRDT.AWORSet.new() |> CRDT.AWORSet.add(:b, 2)
      c = CRDT.AWORSet.new() |> CRDT.AWORSet.add(:c, 3)

      left = CRDT.merge(CRDT.merge(a, b), c) |> CRDT.value() |> Enum.sort()
      right = CRDT.merge(a, CRDT.merge(b, c)) |> CRDT.value() |> Enum.sort()
      assert left == right
    end
  end
end
