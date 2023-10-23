defmodule CRDT.DotContext do
  @moduledoc """
  A DotContext is a data structure that contains a version vector and a dot cloud.

  The version vector is a map from actors to the maximum version of a dot that has been added to
  the dot context on behalf of that actor.
  """

  @type actor :: term
  @type version :: pos_integer
  @type dot :: {actor, version}

  @opaque t :: %__MODULE__{
            version_vector: %{actor => version},
            dot_cloud: list(dot)
          }

  defstruct version_vector: %{}, dot_cloud: []

  @doc """
  Creates a new, empty DotContext.

  ## Examples

        iex> CRDT.DotContext.new()
        %CRDT.DotContext{version_vector: %{}, dot_cloud: []}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Checks if `dot_context` contains `dot`.

  ## Examples

      iex> CRDT.DotContext.new() |> CRDT.DotContext.contains?({:a, 1})
      false
  """
  @spec contains?(t(), dot()) :: boolean
  def contains?(
        %__MODULE__{version_vector: version_vector, dot_cloud: dot_cloud},
        {actor, version} = dot
      ) do
    case version_vector do
      %{^actor => maximum_version} when version <= maximum_version ->
        true

      _ ->
        Enum.any?(dot_cloud, &(&1 == dot))
    end
  end

  @doc """
  Returns the next dot for `actor` and the updated DotContext.

  ## Examples

      iex> CRDT.DotContext.new() |> CRDT.DotContext.next_dot(:a)
      {{:a, 1}, %CRDT.DotContext{version_vector: %{a: 1}, dot_cloud: []}}
  """
  @spec next_dot(t(), actor()) :: {dot(), t()}
  def next_dot(%__MODULE__{version_vector: version_vector} = dot_context, actor) do
    version = Map.get(version_vector, actor, 0) + 1

    {
      {actor, version},
      %{
        dot_context
        | version_vector: Map.put(version_vector, actor, version)
      }
    }
  end

  @doc """
  Adds `dot` to `dot_cloud`.

  ## Examples

      iex> CRDT.DotContext.new() |> CRDT.DotContext.add({:a, 1})
      %CRDT.DotContext{version_vector: %{}, dot_cloud: [{:a, 1}]}
  """
  @spec add(t(), dot()) :: t()
  def add(%__MODULE__{dot_cloud: dot_cloud} = dot_context, dot) do
    %{dot_context | dot_cloud: [dot | dot_cloud]}
  end

  @doc """
  Compresses `dot_context` by removing dots from the dot cloud that are part of the contignuous
  sequence of dots encoded in the version vector.

  ## Examples

      iex> CRDT.DotContext.new()
      ...> |> CRDT.DotContext.add({:a, 2})
      ...> |> CRDT.DotContext.add({:a, 1})
      ...> |> CRDT.DotContext.add({:a, 5})
      ...> |> CRDT.DotContext.add({:a, 3})
      ...> |> CRDT.DotContext.add({:b, 2})
      ...> |> CRDT.DotContext.compress()
      %CRDT.DotContext{version_vector: %{a: 3}, dot_cloud: [{:b, 2}, {:a, 5}]}
  """
  @spec compress(t()) :: t()
  def compress(%__MODULE__{version_vector: version_vector, dot_cloud: dot_cloud}) do
    {version_vector, dot_cloud} =
      for {actor, version} = dot <- Enum.sort(dot_cloud), reduce: {version_vector, []} do
        {version_vector, dot_cloud} ->
          maximum_version = Map.get(version_vector, actor, 0)

          case version do
            version when version == maximum_version + 1 ->
              {Map.put(version_vector, actor, version), dot_cloud}

            version when version <= maximum_version ->
              {version_vector, dot_cloud}

            _ ->
              {version_vector, [dot | dot_cloud]}
          end
      end

    %__MODULE__{version_vector: version_vector, dot_cloud: dot_cloud}
  end

  @doc """
  Merges two DotContexts.

  ## Examples

      iex> CRDT.DotContext.new()
      ...> |> CRDT.DotContext.add({:a, 2})
      ...> |> CRDT.DotContext.add({:a, 1})
      ...> |> CRDT.DotContext.add({:a, 5})
      ...> |> CRDT.DotContext.add({:a, 3})
      ...> |> CRDT.DotContext.merge(
      ...>   CRDT.DotContext.new()
      ...>   |> CRDT.DotContext.add({:a, 4})
      ...>   |> CRDT.DotContext.add({:a, 7})
      ...>   |> CRDT.DotContext.add({:a, 2})
      ...>   |> CRDT.DotContext.add({:b, 2})
      ...> )
      %CRDT.DotContext{version_vector: %{a: 5}, dot_cloud: [{:b, 2}, {:a, 7}]}
  """
  @spec merge(t(), t()) :: t()
  def merge(
        %__MODULE__{version_vector: version_vector_a, dot_cloud: dot_cloud_a},
        %__MODULE__{version_vector: version_vector_b, dot_cloud: dot_cloud_b}
      ) do
    version_vector =
      Map.merge(
        version_vector_a,
        version_vector_b,
        fn _key, version_a, version_b ->
          max(version_a, version_b)
        end
      )

    %__MODULE__{version_vector: version_vector, dot_cloud: dot_cloud_a ++ dot_cloud_b}
    |> compress()
  end
end
