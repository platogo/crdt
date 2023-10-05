defprotocol CRDT.Access do
  @spec get_in(t, nonempty_list(term)) :: term
  def get_in(t, list)
  @spec put_in(t, term, nonempty_list(term), CRDT.crdt()) :: CRDT.crdt()
  def put_in(t, actor, list, value)
  @spec update_in(t, term, nonempty_list(term), (term -> term)) :: CRDT.crdt()
  def update_in(t, actor, list, fun)
end
