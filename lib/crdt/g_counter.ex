defmodule CRDT.GCounter do
  @moduledoc """
  Growing-only counter
  """

  @type actor :: term

  @type t :: %__MODULE__{value: %{actor => non_neg_integer}}

  defstruct value: %{}

  @doc """
  Creates a new, empty Growning-only counter.

  ## Examples

      iex> CRDT.GCounter.new()
      %CRDT.GCounter{value: %{}}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new Growning-only counter with an initial value.

  ## Examples

      iex> CRDT.GCounter.new(a: 1, b: 2)
      %CRDT.GCounter{value: %{a: 1, b: 2}}
  """
  @spec new([{actor(), non_neg_integer()}]) :: t()
  def new(values) do
    %__MODULE__{value: Map.new(values)}
  end

  @doc """
  Increments the counter by the given amount on behalf of an actor.

  ## Examples

      iex> CRDT.GCounter.new()
      ...> |> CRDT.GCounter.inc(:a)
      ...> |> CRDT.GCounter.inc(:b, 2)
      %CRDT.GCounter{value: %{a: 1, b: 2}}
  """
  @spec inc(t(), actor(), non_neg_integer()) :: t()
  def inc(%__MODULE__{value: value}, actor, amount \\ 1) do
    %__MODULE__{value: Map.update(value, actor, amount, &(&1 + amount))}
  end

  defimpl CRDT do
    @doc """
    Returns the value of the counter.

    ## Examples

        iex> CRDT.GCounter.new()
        ...> |> CRDT.GCounter.inc(:a, 1)
        ...> |> CRDT.GCounter.inc(:b, 2)
        ...> |> CRDT.value()
        3
    """
    def value(%CRDT.GCounter{value: value}) do
      Map.values(value) |> Enum.sum()
    end

    @doc """
    Merges two Growning-only counters.

    ## Examples

        iex> CRDT.merge(CRDT.GCounter.new(a: 1, b: 2), CRDT.GCounter.new(a: 2, c: 3))
        %CRDT.GCounter{value: %{a: 2, b: 2, c: 3}}
    """
    def merge(%CRDT.GCounter{value: value1}, %CRDT.GCounter{value: value2}) do
      %CRDT.GCounter{value: Map.merge(value1, value2, fn _k, v1, v2 -> max(v1, v2) end)}
    end
  end
end
