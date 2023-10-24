defmodule CRDT.PNCounter do
  @moduledoc """
  A PN-Counter is a CRDT that can be used to count events that can be both incremented and decremented.

  They are no delta CRDTs, so they are not space efficient. They are however commutative and associative,
  so they can be merged without any conflicts.
  """

  defstruct pos: %{}, neg: %{}

  @type t :: %__MODULE__{
          pos: %{CRDT.actor() => non_neg_integer()},
          neg: %{CRDT.actor() => non_neg_integer()}
        }

  @doc """
  Creates a new PN-Counter.

  Starts with a counter of 0.
  """
  @spec new() :: t
  def new(), do: %__MODULE__{}

  @doc """
  Creates a new PN-Counter with given values.

  ### Examples

      iex> CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"c" => 3})
      %CRDT.PNCounter{neg: %{"c" => 3}, pos: %{"a" => 1, "b" => 2}}
  """
  @spec new(
          pos: %{CRDT.actor() => non_neg_integer()},
          neg: %{CRDT.actor() => non_neg_integer()}
        ) :: t
  def new(pos: pos, neg: neg), do: %__MODULE__{pos: pos, neg: neg}

  @doc """
  Increments the counter on behalf of the actor by the given value, default 1.

  ### Examples

      iex> CRDT.PNCounter.new |> CRDT.PNCounter.increment("a") |> CRDT.value
      1
      iex> CRDT.PNCounter.new |> CRDT.PNCounter.increment("a", 2) |> CRDT.value
      2
  """
  @spec increment(t(), CRDT.actor(), non_neg_integer()) :: t()
  def increment(%__MODULE__{} = counter, actor, value \\ 1) do
    pos = Map.update(counter.pos, actor, value, &(&1 + value))
    %__MODULE__{counter | pos: pos}
  end

  @doc """
  Decrements the counter on behalf of the actor by the given value, default 1.

  ### Examples

      iex> CRDT.PNCounter.new |> CRDT.PNCounter.decrement("a") |> CRDT.value
      -1
      iex> CRDT.PNCounter.new |> CRDT.PNCounter.decrement("a", 2) |> CRDT.value
      -2
  """
  @spec decrement(t(), CRDT.actor(), non_neg_integer()) :: t()
  def decrement(%__MODULE__{} = counter, actor, value \\ 1) do
    neg = Map.update(counter.neg, actor, value, &(&1 + value))
    %__MODULE__{counter | neg: neg}
  end

  @doc """
  Merges two PN-Counters.

  ### Examples

      iex> pncounter1 = CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"c" => 3})
      iex> pncounter2 = CRDT.PNCounter.new(pos: %{"a" => 2, "b" => 1}, neg: %{"d" => 4})
      iex> CRDT.PNCounter.merge(pncounter1, pncounter2)
      %CRDT.PNCounter{neg: %{"c" => 3, "d" => 4}, pos: %{"a" => 2, "b" => 2}}
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{} = counter1, %__MODULE__{} = counter2) do
    pos = Map.merge(counter1.pos, counter2.pos, fn _, v1, v2 -> max(v1, v2) end)
    neg = Map.merge(counter1.neg, counter2.neg, fn _, v1, v2 -> max(v1, v2) end)
    %__MODULE__{pos: pos, neg: neg}
  end

  @doc """
  Returns the actual value of the PN-Counter.

  ### Examples

      iex> CRDT.PNCounter.new |> CRDT.PNCounter.value
      0
      iex> CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"c" => 3}) |> CRDT.PNCounter.value
      0
      iex> CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"b" => 4}) |> CRDT.PNCounter.value
      -1
  """
  @spec value(t()) :: integer()
  def value(%__MODULE__{} = counter) do
    (Map.values(counter.pos) |> Enum.sum()) - (Map.values(counter.neg) |> Enum.sum())
  end
end

defimpl CRDT, for: CRDT.PNCounter do
  @doc """
  ### Examples

      iex> CRDT.PNCounter.new |> CRDT.value
      0
      iex> CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"c" => 3}) |> CRDT.value
      0
      iex> CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"b" => 4}) |> CRDT.value
      -1
  """

  def value(%CRDT.PNCounter{} = counter), do: CRDT.PNCounter.value(counter)

  @doc """
  ### Examples

      iex> pncounter1 = CRDT.PNCounter.new(pos: %{"a" => 1, "b" => 2}, neg: %{"c" => 3})
      iex> pncounter2 = CRDT.PNCounter.new(pos: %{"a" => 2, "b" => 1}, neg: %{"d" => 4})
      iex> CRDT.merge(pncounter1, pncounter2)
      %CRDT.PNCounter{neg: %{"c" => 3, "d" => 4}, pos: %{"a" => 2, "b" => 2}}
  """
  def merge(%CRDT.PNCounter{} = counter1, %CRDT.PNCounter{} = counter2),
    do: CRDT.PNCounter.merge(counter1, counter2)
end
