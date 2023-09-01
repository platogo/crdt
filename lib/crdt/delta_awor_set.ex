defmodule CRDT.DeltaAWORSet do
  @moduledoc false

  @type actor :: term
  @type value :: term

  @type t :: %__MODULE__{
          dot_kernel: CRDT.DotKernel.t(),
          delta: CRDT.DotKernel.t()
        }

  defstruct dot_kernel: CRDT.DotKernel.new(), delta: CRDT.DotKernel.new()

  @doc """
  Creates a new, empty DeltaAWORSet.

  ## Examples

      iex> CRDT.DeltaAWORSet.new()
      %CRDT.DeltaAWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{}, dot_cloud: []},
          entries: %{}
        },
        delta: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{}, dot_cloud: []},
          entries: %{}
        }
      }
  """
  @spec new() :: t
  def new, do: %__MODULE__{}

  @doc """
  Adds an element to the DeltaAWORSet on behalf of `actor`.

  ## Examples:

      iex> CRDT.DeltaAWORSet.new() |> CRDT.DeltaAWORSet.add(:a, "value")
      %CRDT.DeltaAWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        },
        delta: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        }
      }
  """
  @spec add(t, actor, value) :: t
  def add(%__MODULE__{dot_kernel: dot_kernel, delta: delta}, actor, value) do
    {dot_kernel, delta} =
      {dot_kernel, delta}
      |> CRDT.DotKernel.remove(value)
      |> CRDT.DotKernel.add(actor, value)

    %__MODULE__{dot_kernel: dot_kernel, delta: delta}
  end

  @doc """
  Removes an element from the DeltaAWORSet.

  ## Examples:

      iex> CRDT.DeltaAWORSet.new() |> CRDT.DeltaAWORSet.add(:a, "value") |> CRDT.DeltaAWORSet.remove("value")
      %CRDT.DeltaAWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{}
        },
        delta: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        }
      }
  """
  @spec remove(t, value) :: t
  def remove(%__MODULE__{dot_kernel: dot_kernel, delta: delta}, value) do
    {dot_kernel, delta} =
      {dot_kernel, delta}
      |> CRDT.DotKernel.remove(value)

    %__MODULE__{dot_kernel: dot_kernel, delta: delta}
  end

  @doc """
  Returns member values.

  ## Examples:

      iex> CRDT.DeltaAWORSet.new() |> CRDT.DeltaAWORSet.add(:a, "value") |> CRDT.DeltaAWORSet.value()
      ["value"]
  """
  @spec value(t) :: list
  def value(%__MODULE__{dot_kernel: dot_kernel}) do
    CRDT.DotKernel.values(dot_kernel)
  end

  @doc """
  Merges two DeltaAWORSets.

  ## Examples:

      iex> CRDT.DeltaAWORSet.new()
      ...> |> CRDT.DeltaAWORSet.add(:a, "value1")
      ...> |> CRDT.DeltaAWORSet.merge(
      ...>   CRDT.DeltaAWORSet.new()
      ...>   |> CRDT.DeltaAWORSet.add(:b, "value2")
      ...> )
      %CRDT.DeltaAWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1, b: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value1", {:b, 1} => "value2"}
        },
        delta: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1, b: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value1", {:b, 1} => "value2"}
        }
      }
  """
  @spec merge(t, t) :: t
  def merge(
        %__MODULE__{dot_kernel: dot_kernel_a, delta: delta_a},
        %__MODULE__{dot_kernel: dot_kernel_b, delta: delta_b}
      ) do
    %__MODULE__{
      dot_kernel: CRDT.DotKernel.merge(dot_kernel_a, dot_kernel_b),
      delta: CRDT.DotKernel.merge(delta_a, delta_b)
    }
  end

  @doc """
  Merges a DeltaAWORSet with a DeltaAWORSet delta.

  ## Examples:

      iex> a = CRDT.DeltaAWORSet.new()
      ...>     |> CRDT.DeltaAWORSet.add(:a, "value1")
      ...> b = CRDT.DeltaAWORSet.new()
      ...>     |> CRDT.DeltaAWORSet.add(:b, "value2")
      ...> CRDT.DeltaAWORSet.merge_delta(a, b.delta)
      %CRDT.DeltaAWORSet{
        dot_kernel: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1, b: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value1", {:b, 1} => "value2"}
        },
        delta: %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1, b: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value1", {:b, 1} => "value2"}
        }
      }
  """
  @spec merge_delta(t, CRDT.DotKernel.t()) :: t
  def merge_delta(%__MODULE__{dot_kernel: dot_kernel_a, delta: delta_a}, delta) do
    %__MODULE__{
      dot_kernel: CRDT.DotKernel.merge(dot_kernel_a, delta),
      delta: CRDT.DotKernel.merge(delta_a, delta)
    }
  end
end
