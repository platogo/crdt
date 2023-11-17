defprotocol CRDT.Access do
  @moduledoc """
  This protocol defines the access methods for CRDTs.
  """
  @doc """
  Returns the value at the given path.
  """
  @spec get_in(t(), nonempty_list(term())) :: term()
  def get_in(t, list)

  @doc """
  Adds the given value to the given path.
  """
  @spec put_in(t(), term(), nonempty_list(term()), CRDT.crdt()) :: CRDT.crdt()
  def put_in(t, actor, list, value)

  @doc """
  Updates the value at the given path.
  """
  @spec update_in(t(), term(), nonempty_list(term()), (term() -> term())) :: CRDT.crdt()
  def update_in(t, actor, list, fun)
end
