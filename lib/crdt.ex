defprotocol CRDT do
  @moduledoc """
  Protocol defining the interface for CRDTs.
  """

  @doc """
  Returns the actual value of the CRDT
  """
  @spec value(t) :: term
  def value(crdt)

  @doc """
  Merges two CRDTs.
  """
  @spec merge(t, t) :: t
  def merge(crdt1, crdt2)
end
