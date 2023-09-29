defprotocol CRDT do
  @moduledoc """
  Documentation for `CRDT`.
  """

  @spec value(t) :: term
  def value(crdt)

  @spec merge(t, t) :: t
  def merge(crdt1, crdt2)
end
