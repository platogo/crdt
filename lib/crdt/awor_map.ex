defmodule CRDT.AWORMap do
  @moduledoc false

  @type actor :: term
  @type key :: term
  @type value :: term

  @type t :: %__MODULE__{
          keys: CRDT.AWORSet.t(),
          entries: %{key => value}
        }

  defstruct keys: CRDT.AWORSet.new(), entries: %{}

  @doc """
  Creates a new, empty AWORMap.

  ## Examples:

      iex> CRDT.AWORMap.new()
      %CRDT.AWORMap{
        keys: %CRDT.AWORSet{
          dot_kernel: %CRDT.DotKernel{
            dot_context: %CRDT.DotContext{version_vector: %{}, dot_cloud: []},
            entries: %{}
          }
        },
        entries: %{}
      }
  """
  @spec new() :: t
  def new, do: %__MODULE__{}

  @doc """
  Puts the given `value` under `key` into the AWORMap on behalf of `actor`.

  ## Examples:

      iex> CRDT.AWORMap.new() |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      %CRDT.AWORMap{
        keys: %CRDT.AWORSet{
          dot_kernel: %CRDT.DotKernel{
            dot_context: %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []},
            entries: %{{:a, 1} => :key}
          }
        },
        entries: %{key: %CRDT.GCounter{}}
      }
  """
  @spec put(t, actor, key, value) :: t
  def put(%__MODULE__{keys: keys, entries: entries}, actor, key, value) do
    CRDT.impl_for!(value)

    %__MODULE__{
      keys: CRDT.AWORSet.add(keys, actor, key),
      entries: Map.put(entries, key, value)
    }
  end

  @doc """
  Fetches the value for the given `key` from the AWORMap.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.fetch(:key)
      {:ok, %CRDT.GCounter{}}
  """
  @spec fetch(t, key) :: {:ok, value} | :error
  def fetch(%__MODULE__{entries: entries}, key), do: Map.fetch(entries, key)

  @doc """
  Fetches the value for the given `key` from the AWORMap.

  If AWORMap contains `key`, the corresponding value is returned. If
  AWORMap doesn't contain `key`, a `KeyError` exception is raised.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.fetch!(:key)
      %CRDT.GCounter{}

      iex> CRDT.AWORMap.new() |> CRDT.AWORMap.fetch!(:key)
      ** (KeyError) key :key not found in: %{}
  """
  @spec fetch!(t, key) :: value
  def fetch!(%__MODULE__{entries: entries}, key), do: Map.fetch!(entries, key)

  @doc """
  Gets the `key` in the AWORMap.

  ## Examples:
      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.get(:key)
      %CRDT.GCounter{}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.get(:key, CRDT.GCounter.new())
      %CRDT.GCounter{}
  """
  @spec get(t, key, value) :: value
  def get(%__MODULE__{entries: entries}, key, default \\ nil), do: Map.get(entries, key, default)

  @doc """
  Updates the `key` in the AWORMap with the the given function to the value on behalf of `actor`.

  If `key` is present in AWORMap then the existing value is passed to `fun` and its result is
  used as the updated value of `key`. If `key` is
  not present in AWORMap, `default` is inserted as the value of `key`. The default
  value will not be passed through the update function.

  ## Examples:
      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.update(:a, :key, CRDT.GCounter.new(a: 5), &(CRDT.GCounter.inc(&1, :a)))
      ...> |> CRDT.value()
      %{key: 1}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.update(:a, :key, CRDT.GCounter.new(a: 5), &(CRDT.GCounter.inc(&1, :a)))
      ...> |> CRDT.value()
      %{key: 5}
  """
  @spec update(t, actor, key, value, (value -> value)) :: t
  def update(%__MODULE__{entries: entries} = awor_map, actor, key, default, fun)
      when is_function(fun) do
    CRDT.impl_for!(default)

    case entries do
      %{^key => value} ->
        new_value = fun.(value)
        CRDT.impl_for!(new_value)
        put(awor_map, actor, key, new_value)

      %{} ->
        put(awor_map, actor, key, default)
    end
  end

  @doc """
  Updates the `key` in the AWORMap with the given function on behalf of `actor`.

  If `key` is present in AWORMap then the existing value is passed to `fun` and its result is
  used as the updated value of `key`. If `key` is
  not present in AWORMap, a `KeyError` exception is raised.

  ## Examples

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.update!(:a, :key, &(CRDT.GCounter.inc(&1, :a)))
      ...> |> CRDT.value()
      %{key: 1}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.update!(:a, :key, &(CRDT.GCounter.inc(&1, :a)))
      ...> |> CRDT.value()
      ** (KeyError) key :key not found in: %{}
  """
  @spec update!(t, actor, key, (value -> value)) :: t
  def update!(%__MODULE__{entries: entries} = awor_map, actor, key, fun)
      when is_function(fun) do
    value = Map.fetch!(entries, key)

    put(awor_map, actor, key, fun.(value))
  end

  defimpl CRDT do
    @doc """
    Returns the value the map value.

    ## Examples:

        iex> CRDT.AWORMap.new()
        ...> |> CRDT.AWORMap.put(:a, :counter, CRDT.GCounter.new(a: 1, b: 2))
        ...> |> CRDT.AWORMap.put(
        ...>   :a,
        ...>   :map,
        ...>   CRDT.AWORMap.new() |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
        ...> )
        ...> |> CRDT.value()
        %{counter: 3, map: %{key: 0}}
    """
    def value(%CRDT.AWORMap{entries: entries}) do
      for {key, value} <- entries, into: %{} do
        {
          key,
          if CRDT.impl_for(value) do
            CRDT.value(value)
          else
            value
          end
        }
      end
    end

    @doc """
    Merges two AWORMaps.

    ## Examples:

        iex> CRDT.merge(
        ...>   CRDT.AWORMap.new()
        ...>   |> CRDT.AWORMap.put(:a, :counter, CRDT.GCounter.new(a: 1)),
        ...>   CRDT.AWORMap.new()
        ...>   |> CRDT.AWORMap.put(:b, :counter, CRDT.GCounter.new(b: 2))
        ...> )
        %CRDT.AWORMap{
          keys: %CRDT.AWORSet{
            dot_kernel: %CRDT.DotKernel{
              dot_context: %CRDT.DotContext{
                version_vector: %{a: 1, b: 1},
                dot_cloud: []
              },
              entries: %{{:a, 1} => :counter, {:b, 1} => :counter}
            }
          },
          entries: %{counter: %CRDT.GCounter{value: %{a: 1, b: 2}}}
        }
    """
    def merge(
          %CRDT.AWORMap{keys: keys_a, entries: entries_a},
          %CRDT.AWORMap{keys: keys_b, entries: entries_b}
        ) do
      keys = CRDT.merge(keys_a, keys_b)

      entries =
        for key <- CRDT.value(keys), reduce: %{} do
          entries ->
            case {entries_a, entries_b} do
              {%{^key => value_a}, %{^key => value_b}} ->
                Map.put(entries, key, CRDT.merge(value_a, value_b))

              {%{^key => value_a}, %{}} ->
                Map.put(entries, key, value_a)

              {%{}, %{^key => value_b}} ->
                Map.put(entries, key, value_b)

              {%{}, %{}} ->
                entries
            end
        end

      %CRDT.AWORMap{keys: keys, entries: entries}
    end
  end
end
