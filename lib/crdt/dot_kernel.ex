defmodule CRDT.DotKernel do
  @moduledoc false

  @type actor :: term
  @type version :: pos_integer
  @type dot :: {actor, version}
  @type value :: term

  @opaque t :: %__MODULE__{
            dot_context: CRDT.DotContext.t(),
            entries: %{dot => value}
          }

  defstruct dot_context: CRDT.DotContext.new(), entries: %{}

  @doc """
  Creates a new, empty DotKernel.

  ## Examples

      iex> CRDT.DotKernel.new()
      %CRDT.DotKernel{
        dot_context: %CRDT.DotContext{version_vector: %{}, dot_cloud: []},
        entries: %{}
      }
  """
  @spec new() :: t
  def new, do: %__MODULE__{}

  @doc """
  Adds a `value` to the DotKernel on behalf of `actor`.
  Returns the updated DotKernel.

  Can also be used with a DotKernel/delta tuple.

  ## Examples

      iex> CRDT.DotKernel.new() |> CRDT.DotKernel.add(:a, "value")
      %CRDT.DotKernel{
        dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
        entries: %{{:a, 1} => "value"}
      }

      iex> {CRDT.DotKernel.new(), CRDT.DotKernel.new()} |> CRDT.DotKernel.add(:a, "value")
      {
        %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        },
        %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        }
      }
  """
  @spec add(t, actor, value) :: t
  def add(%__MODULE__{dot_context: dot_context, entries: entries}, actor, value) do
    {dot, dot_context} = CRDT.DotContext.next_dot(dot_context, actor)

    %__MODULE__{
      dot_context: dot_context,
      entries: Map.put(entries, dot, value)
    }
  end

  @spec add({t, t}, actor, value) :: {t, t}
  def add(
        {
          %__MODULE__{dot_context: dot_context, entries: entries},
          %__MODULE__{dot_context: delta_dot_context, entries: delta_entries}
        },
        actor,
        value
      ) do
    {dot, dot_context} = CRDT.DotContext.next_dot(dot_context, actor)

    {
      %__MODULE__{
        dot_context: dot_context,
        entries: Map.put(entries, dot, value)
      },
      %__MODULE__{
        dot_context: CRDT.DotContext.add(delta_dot_context, dot) |> CRDT.DotContext.compress(),
        entries: Map.put(delta_entries, dot, value)
      }
    }
  end

  @doc """
  Removes a `value` from the DotKernel.

  Can also be used with a DotKernel/delta tuple.

  ## Examples

      iex> CRDT.DotKernel.new()
      ...> |> CRDT.DotKernel.add(:a, "value")
      ...> |> CRDT.DotKernel.remove("value")
      %CRDT.DotKernel{
        dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
        entries: %{}
      }

      iex> {CRDT.DotKernel.new(), CRDT.DotKernel.new()}
      ...> |> CRDT.DotKernel.add(:a, "value")
      ...> |> CRDT.DotKernel.remove("value")
      {
        %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{}
        },
        %CRDT.DotKernel{
          dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
          entries: %{{:a, 1} => "value"}
        }
      }
  """
  @spec remove(t, value) :: t
  def remove(%__MODULE__{entries: entries} = dot_kernel, value) do
    entries =
      for {dot, entry_value} <- entries, entry_value == value, reduce: entries do
        entries ->
          # The corresponding dot says in the dot context and acts as a tombstone.
          # So we can avoid readding it when merging with an out of date replica.
          Map.delete(entries, dot)
      end

    %__MODULE__{dot_kernel | entries: entries}
  end

  @spec remove({t, t}, value) :: {t, t}
  def remove(
        {
          %__MODULE__{entries: entries} = dot_kernel,
          %__MODULE__{dot_context: delta_dot_context} = delta
        },
        value
      ) do
    {entries, delta_dot_context} =
      for {dot, entry_value} <- entries,
          entry_value == value,
          reduce: {entries, delta_dot_context} do
        {entries, delta_dot_context} ->
          {
            Map.delete(entries, dot),
            CRDT.DotContext.add(delta_dot_context, dot) |> CRDT.DotContext.compress()
          }
      end

    {
      %__MODULE__{dot_kernel | entries: entries},
      %__MODULE__{delta | dot_context: delta_dot_context}
    }
  end

  @doc """
  Returns active values.

  ## Examples

      iex> CRDT.DotKernel.new()
      ...> |> CRDT.DotKernel.add(:a, "value")
      ...> |> CRDT.DotKernel.values()
      ["value"]

  """
  @spec values(t) :: list
  def values(%__MODULE__{entries: entries}) do
    Map.values(entries)
  end

  @doc """
  Merges two DotContexts.

  ## Examples

      iex> CRDT.DotKernel.new()
      ...> |> CRDT.DotKernel.add(:a, "value1")
      ...> |> CRDT.DotKernel.add(:a, "value2")
      ...> |> CRDT.DotKernel.merge(
      ...>   CRDT.DotKernel.new()
      ...>   |> CRDT.DotKernel.add(:a, "value1")
      ...>   |> CRDT.DotKernel.add(:a, "value2")
      ...>   |> CRDT.DotKernel.remove("value2")
      ...> )
      %CRDT.DotKernel{
        dot_context: %CRDT.DotContext{version_vector: %{a: 2}, dot_cloud: []},
        entries: %{{:a, 1} => "value1"}
      }
  """
  @spec merge(t, t) :: t
  def merge(
        %__MODULE__{dot_context: dot_context_a, entries: entries_a},
        %__MODULE__{dot_context: dot_context_b, entries: entries_b}
      ) do
    entries =
      for {dot, value} <- entries_b, reduce: entries_a do
        entries ->
          # Add unseen entries from b, unless there's a tombstone in the dot_context.
          if not (Map.has_key?(entries, dot) or CRDT.DotContext.contains?(dot_context_a, dot)) do
            Map.put(entries, dot, value)
          else
            entries
          end
      end

    entries =
      for {dot, _value} <- entries_a, reduce: entries do
        entries ->
          if CRDT.DotContext.contains?(dot_context_b, dot) and not Map.has_key?(entries_b, dot) do
            # Remove entries that were deleted in b.
            Map.delete(entries, dot)
          else
            entries
          end
      end

    %__MODULE__{
      dot_context: CRDT.DotContext.merge(dot_context_a, dot_context_b),
      entries: entries
    }
  end
end
