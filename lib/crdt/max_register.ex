defmodule CRDT.MaxRegister do
  @moduledoc """
  Max register that holds a single value and uses max function to resolve conflicts.
  """

  @type t :: %__MODULE__{value: non_neg_integer}

  defstruct value: 0

  def new, do: %__MODULE__{}

  @doc """
  Sets the value of the max register to the given value if it is greater than the current value

  ## Examples

      iex> CRDT.MaxRegister.new(123)
      %CRDT.MaxRegister{value: 123}
  """

  def new(value), do: %__MODULE__{value: value}

  @doc """
  Sets the value of the max register to the given value if it is greater than the current value

  ## Examples

      iex> CRDT.MaxRegister.new()
      ...> |> CRDT.MaxRegister.update(123)
      %CRDT.MaxRegister{value: 123}
  """
  @spec update(__MODULE__.t(), non_neg_integer()) :: __MODULE__.t()
  def update(%__MODULE__{value: old_value}, value) do
    %__MODULE__{value: max(old_value, value)}
  end
end

defimpl CRDT, for: CRDT.MaxRegister do
  @doc """
  Returns the value of the max register

      iex> CRDT.MaxRegister.new()
      ...> |> CRDT.MaxRegister.update(123)
      ...> |> CRDT.value()
      123
  """
  def value(%CRDT.MaxRegister{value: value}), do: value

  @doc """
  Merges two max registers and returns the one with the greater value

      iex> CRDT.MaxRegister.new()
      ...> |> CRDT.MaxRegister.update(12345)
      ...> |> CRDT.merge(CRDT.MaxRegister.new() |> CRDT.MaxRegister.update(123))
      ...> |> CRDT.value()
      12345
  """

  def merge(%CRDT.MaxRegister{value: value1}, %CRDT.MaxRegister{value: value2}) do
    %CRDT.MaxRegister{value: max(value1, value2)}
  end
end
