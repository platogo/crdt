defmodule CRDT.LWWRegister do
  @moduledoc """
  A last-write-wins register

  Is used to store simple values with a timestamp. Using `merge` on two registers
  will result in creating a register with the value corresponding to the most
  recent timestamp
  """

  @type t :: %CRDT.LWWRegister{
          value: term() | nil,
          timestamp: pos_integer()
        }

  defstruct value: nil, timestamp: System.system_time()

  @doc """
  Creates a new register with the value set to the supplied parameter or nil
  and the current timestamp as returned by `System.system_time/0`

      iex> CRDT.LWWRegister.new()
      %CRDT.LWWRegister{value: nil}

      iex> CRDT.LWWRegister.new("data")
      %CRDT.LWWRegister{value: "data"}

  """
  @spec new :: t()
  def new, do: %CRDT.LWWRegister{}

  @spec new(term()) :: t()
  def new(data), do: %CRDT.LWWRegister{value: data}

  @doc """
  Sets the value of the register to the supplied parameter and updates the
  timestamp to the current timestamp as returned by `System.system_time/0`

      iex> CRDT.LWWRegister.new() |> CRDT.LWWRegister.set("data")
      ...> |> CRDT.value()
      "data"

  """
  @spec set(t(), term()) :: t()
  def set(_register, data) do
    %CRDT.LWWRegister{value: data, timestamp: System.system_time()}
  end
end

defimpl CRDT, for: CRDT.LWWRegister do
  @moduledoc """
  Implements the CRDT behaviour for the LWWRegister
  """
  @doc """
  Returns the value of the register

      iex> CRDT.LWWRegister.new("data") |> CRDT.value()
      "data"
  """
  def value(register), do: register.value

  @doc """
  Merges two registers and returns a new register with the value corresponding
  to the most recent timestamp

      iex> CRDT.LWWRegister.new("data") |> CRDT.merge(CRDT.LWWRegister.new("data2"))
      ...> |> CRDT.value()
      "data2"
  """

  def merge(register1, register2) do
    if register1.timestamp > register2.timestamp do
      register1
    else
      register2
    end
  end
end
