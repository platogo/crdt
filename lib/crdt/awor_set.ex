defmodule CRDT.AWORSet do
  @moduledoc """
  An add-wins observed-remove set (AWORSet) is a set that allows adding and
  removing elements.

  It is a variant of a 2P-Set that uses a DotKernel to track the additions and removals.
  """

  @type actor :: term
  @type value :: term

  @type t :: %__MODULE__{
          dot_kernel: CRDT.DotKernel.t()
        }

  defstruct dot_kernel: CRDT.DotKernel.new()

  @doc """
  Creates a new, empty AWORSet.

  ## Examples

      iex> CRDT.AWORSet.new()
      %CRDT.AWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{}, dot_cloud: []},
          entries: %{}
        }
      }
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds an element to the AWORSet on behalf of `actor`.

  ## Examples:

      iex> CRDT.AWORSet.new() |> CRDT.AWORSet.add(:a, "value")
      %CRDT.AWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        }
      }
  """
  @spec add(t(), actor(), value()) :: t()
  def add(%__MODULE__{dot_kernel: dot_kernel}, actor, value) do
    %__MODULE__{
      dot_kernel:
        dot_kernel
        |> CRDT.DotKernel.remove(value)
        |> CRDT.DotKernel.add(actor, value)
    }
  end

  @doc """
  Removes an element from the AWORSet.

  ## Examples:

      iex> CRDT.AWORSet.new() |> CRDT.AWORSet.add(:a, "value") |> CRDT.AWORSet.remove("value")
      %CRDT.AWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{}
        }
      }
  """
  @spec remove(t(), value()) :: t()
  def remove(%__MODULE__{dot_kernel: dot_kernel}, value) do
    %__MODULE__{dot_kernel: CRDT.DotKernel.remove(dot_kernel, value)}
  end

  defimpl CRDT do
    @doc """
    Returns member values.

    ## Examples:

        iex> CRDT.AWORSet.new()
        ...> |> CRDT.AWORSet.add(:a, "value")
        ...> |> CRDT.value()
        ["value"]
    """
    def value(%CRDT.AWORSet{dot_kernel: dot_kernel}) do
      CRDT.DotKernel.values(dot_kernel) |> Enum.uniq()
    end

    @doc """
    Merges two AWORSets.

    ## Examples:

        iex> CRDT.AWORSet.new()
        ...> |> CRDT.AWORSet.add(:a, "value1")
        ...> |> CRDT.merge(
        ...>   CRDT.AWORSet.new()
        ...>   |> CRDT.AWORSet.add(:b, "value2")
        ...> )
        %CRDT.AWORSet{
          dot_kernel: %CRDT.DotKernel{
            dot_context: %CRDT.DotContext{version_vector: %{a: 1, b: 1}, dot_cloud: []},
            entries: %{{:a, 1} => "value1", {:b, 1} => "value2"}
          }
        }
    """
    def merge(
          %CRDT.AWORSet{dot_kernel: dot_kernel_a},
          %CRDT.AWORSet{dot_kernel: dot_kernel_b}
        ) do
      %CRDT.AWORSet{
        dot_kernel: CRDT.DotKernel.merge(dot_kernel_a, dot_kernel_b)
      }
    end
  end
end
