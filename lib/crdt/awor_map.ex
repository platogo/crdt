defmodule CRDT.AWORMap do
  @moduledoc false

  @type actor :: term
  @type key :: term
  @type crdt :: term

  @type t :: %__MODULE__{
          keys: CRDT.AWORSet.t(),
          entries: %{key => crdt}
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
  Puts the given `crdt` under `key` into the AWORMap on behalf of `actor`.

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
  @spec put(t, actor, key, crdt) :: t
  def put(%__MODULE__{keys: keys, entries: entries}, actor, key, crdt) do
    CRDT.impl_for!(crdt)

    %__MODULE__{
      keys: CRDT.AWORSet.add(keys, actor, key),
      entries: Map.put(entries, key, crdt)
    }
  end

  @doc """
  Fetches the crdt for the given `key` from the AWORMap.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.fetch(:key)
      {:ok, %CRDT.GCounter{}}
  """
  @spec fetch(t, key) :: {:ok, crdt} | :error
  def fetch(%__MODULE__{entries: entries}, key), do: Map.fetch(entries, key)

  @doc """
  Fetches the crdt for the given `key` from the AWORMap.

  If AWORMap contains `key`, the corresponding crdt is returned. If
  AWORMap doesn't contain `key`, a `KeyError` exception is raised.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.fetch!(:key)
      %CRDT.GCounter{}

      iex> CRDT.AWORMap.new() |> CRDT.AWORMap.fetch!(:key)
      ** (KeyError) key :key not found in: %{}
  """
  @spec fetch!(t, key) :: crdt
  def fetch!(%__MODULE__{entries: entries}, key), do: Map.fetch!(entries, key)

  @doc """
  Gets the `key` in the AWORMap. If `key` is not present in AWORMap, `default` is returned.

  ## Examples:
      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
      ...> |> CRDT.AWORMap.get(:key)
      %CRDT.GCounter{}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.get(:key, CRDT.GCounter.new())
      %CRDT.GCounter{}
  """
  @spec get(t, key, crdt) :: crdt
  def get(%__MODULE__{entries: entries}, key, default \\ nil), do: Map.get(entries, key, default)

  @doc """
  Updates the `key` in the AWORMap with the the given function to the crdt on behalf of `actor`.

  If `key` is present in AWORMap then the existing crdt is passed to `fun` and its result is
  used as the updated crdt of `key`. If `key` is
  not present in AWORMap, `default` is inserted as the crdt of `key`. The default
  crdt will not be passed through the update function.

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
  @spec update(t, actor, key, crdt, (crdt -> crdt)) :: t
  def update(%__MODULE__{entries: entries} = awor_map, actor, key, default, fun)
      when is_function(fun) do
    CRDT.impl_for!(default)

    case entries do
      %{^key => crdt} ->
        new_crdt = fun.(crdt)
        CRDT.impl_for!(new_crdt)
        put(awor_map, actor, key, new_crdt)

      %{} ->
        put(awor_map, actor, key, default)
    end
  end

  @doc """
  Updates the `key` in the AWORMap with the given function on behalf of `actor`.

  If `key` is present in AWORMap then the existing crdt is passed to `fun` and its result is
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
  @spec update!(t, actor, key, (crdt -> crdt)) :: t
  def update!(%__MODULE__{entries: entries} = awor_map, actor, key, fun)
      when is_function(fun) do
    crdt = Map.fetch!(entries, key)

    put(awor_map, actor, key, fun.(crdt))
  end
end

defimpl CRDT.Access, for: CRDT.AWORMap do
  @doc """
  Retrieves the value by recursively following the list of keys in a nested AWORMap.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:actor, :key_a,
      ...>   CRDT.AWORMap.new() |> CRDT.AWORMap.put(
      ...>     :actor, :key_b, CRDT.GCounter.new(a: 1)))
      ...> |> CRDT.Access.get_in([:key_a, :key_b])
      %CRDT.GCounter{value: %{a: 1}}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.Access.get_in([:key_a, :key_b])
      ** (KeyError) key :key_a not found in: %{}

  """
  @spec get_in(CRDT.AWORMap.t(), nonempty_list(term), CRDT.crdt() | nil) :: CRDT.crdt() | nil
  def get_in(map, list, default \\ nil)

  def get_in(map, [head], default),
    do: CRDT.AWORMap.get(map, head, default)

  def get_in(map, [head | tail], default),
    do: get_in(CRDT.AWORMap.fetch!(map, head), tail, default)

  @doc """
  Updates the value by recursively following the list of keys in a nested AWORMap
  with the given crdt on behalf of `actor`.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:actor, :key_a,
      ...>   CRDT.AWORMap.new() |> CRDT.AWORMap.put(
      ...>     :actor, :key_b, CRDT.GCounter.new(a: 1)))
      ...> |> CRDT.Access.put_in(:actor, [:key_a, :key_b],
      ...>     CRDT.GCounter.new(a: 1, b: 2))
      ...> |> CRDT.value()
      %{key_a: %{key_b: 3}}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.Access.put_in(:actor, [:key_a, :key_b],
      ...>     CRDT.GCounter.new(a: 1, b: 2))
      ** (KeyError) key :key_a not found in: %{}

  """
  @spec put_in(CRDT.AWORMap.t(), CRDT.actor(), list, CRDT.crdt()) :: CRDT.crdt()
  def put_in(map, actor, [head], crdt),
    do: CRDT.AWORMap.put(map, actor, head, crdt)

  def put_in(%module{entries: _entries} = map, actor, [head | tail], crdt),
    do: CRDT.AWORMap.put(map, actor, head, put_in(module.fetch!(map, head), actor, tail, crdt))

  @doc """
  Updates the key by recursively following the list of keys in the nested AWORMap
  with the the given function to the crdt on behalf of `actor`.

  ## Examples:

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:actor, :key_a,
      ...>   CRDT.AWORMap.new() |> CRDT.AWORMap.put(
      ...>     :actor, :key_b, CRDT.GCounter.new(a: 1)))
      ...> |> CRDT.Access.update_in(:actor, [:key_a, :key_b],
      ...>     &(CRDT.GCounter.inc(&1, :a)))
      ...> |> CRDT.value()
      %{key_a: %{key_b: 2}}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.Access.update_in(:actor, [:key_a, :key_b],
      ...>     &(CRDT.GCounter.inc(&1, :a)))
      ** (KeyError) key :key_a not found in: %{}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:actor, :key_a, CRDT.AWORMap.new())
      ...> |> CRDT.Access.update_in(:actor, [:key_a, :key_b],
      ...>     &(CRDT.GCounter.inc(&1, :a)))
      ** (KeyError) key :key_b not found in: %{}

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:actor, :key_a,
      ...>     CRDT.AWORMap.new()
      ...>     |> CRDT.AWORMap.put(:actor, :key_b,
      ...>       CRDT.GCounter.new(a: 1)))
      ...> |> CRDT.Access.update_in(:actor, [:key_a, :key_b], :fail)
      ...> |> CRDT.value()
      ** (FunctionClauseError) no function clause matching in CRDT.Access.CRDT.AWORMap.update_in/4

      iex> CRDT.AWORMap.new()
      ...> |> CRDT.AWORMap.put(:actor, :key_a,
      ...>   CRDT.AWORMap.new()
      ...>   |> CRDT.AWORMap.put(:actor, :key_b, CRDT.GCounter.new(a: 1)))
      ...> |> CRDT.Access.update_in(:actor, :key_a,
      ...>   &(CRDT.AWORMap.put(&1, :actor, :key_b, CRDT.GCounter.new(a: 1, b: 2))))
      ...> |> CRDT.value()
      ** (FunctionClauseError) no function clause matching in CRDT.Access.CRDT.AWORMap.update_in/4

  """
  @spec update_in(CRDT.AWORMap.t(), CRDT.actor(), list, (CRDT.crdt() -> CRDT.crdt())) ::
          CRDT.AWORMap.t()
  def update_in(map, actor, [head], fun) when is_function(fun, 1),
    do: CRDT.AWORMap.update!(map, actor, head, fun)

  def update_in(map, actor, [head | tail], fun)
      when is_function(fun, 1),
      do: CRDT.AWORMap.update!(map, actor, head, &update_in(&1, actor, tail, fun))
end

defimpl CRDT, for: CRDT.AWORMap do
  @doc """
  Returns the map value.

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
    for {key, crdt} <- entries, into: %{} do
      {
        key,
        if CRDT.impl_for(crdt) do
          CRDT.value(crdt)
        else
          crdt
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
            {%{^key => crdt_a}, %{^key => crdt_b}} ->
              Map.put(entries, key, CRDT.merge(crdt_a, crdt_b))

            {%{^key => crdt_a}, %{}} ->
              Map.put(entries, key, crdt_a)

            {%{}, %{^key => crdt_b}} ->
              Map.put(entries, key, crdt_b)

            {%{}, %{}} ->
              entries
          end
      end

    %CRDT.AWORMap{keys: keys, entries: entries}
  end
end
