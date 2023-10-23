defprotocol CRDT do
  @moduledoc """
  Protocol defining the interface for CRDTs.

  For more information on CRDTs, see https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type
  """

  @type actor :: term()
  @type key :: term()
  @type crdt :: term()

  @doc """
  Returns the actual value of the CRDT
  """
  @spec value(t()) :: term()
  def value(crdt)

  @doc """
  Merges two CRDTs.
  """
  @spec merge(t(), t()) :: t()
  def merge(crdt1, crdt2)
end
