# CRDT

This is a set of basic, composable and extensible CRDTs.

A CRDT is defined as Conflict-free Replicated Data Type,
see https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type

Please refer to the API Reference for usage documentation and examples.

## Table of Contents

- [Installation](#installation)
- [List of implemented CRDTs](#list-of-implemented-crdts)
- [Usage](#usage)
  - [GCounter](#crdt-gcounter)
  - [PNCounter](#crdt-pncounter)
  - [LWWRegister](#crdt-lwwregister)
  - [AWORMap](#crdt-awormap)
- [Known issues and limitations](#known-issues-and-limitations)
- [Acknowledgments](#acknowledgments)
- [License](#license)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `crdt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:crdt, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/crdt>.

## List of implemented CRDTs

```
           +----------------++---------++-----------++------------++---------++----------------+
Data Type  |  LWW-Register  || AWORSet || G-Counter || PN-Counter || AWORMap || Delta-AWORSet  |
           +----------------++---------++-----------++------------++---------++----------------+
CRDT Type  |  Commutative    |                        Convergent                               |
           +-----------------+-----------------------------------------------------------------+
```

## Usage

These are simple examples that should give an idea of how to use some of the data types,
and what to expect in each case.

### `CRDT.GCounter`

A `CRDT.GCounter` is a growth-only counter. It can be initialized with positive values on
behalf of actors. The resulting value will always be the sum of the values across actors.
An empty counter will have the value '0'.


#### Initializing

``` elixir
counter = CRDT.GCounter.new
CRDT.value(counter) # => 0

counter = CRDT.GCounter.new(actor1: 5, actor2: 10)
CRDT.value(counter) # => 15
```

#### Incrementing

Incrementing a `CRDT.GCounter` is done via the `CRDT.GCounter.increment/2` function.
If the actor key does not exist yet, it is assumed that the given value is the starting
value.

``` elixir
counter = CRDT.GCounter.new
counter = counter |> CRDT.GCounter.increment(:a, 5) # => %CRDT.GCounter{value: %{a: 5}}
counter = counter |> CRDT.GCounter.increment(:a, 2) # => %CRDT.GCounter{value: %{a: 7}}
CRDT.value(counter) # => 7
```

#### Merging

Merging two GCounters preserves all actors in both, taking the higher value if an actor exists in both GCounters.

``` elixir
counter1 = CRDT.GCounter.new(actor1: 5, actor2: 3)
counter2 = CRDT.GCounter.new(actor2: 1, actor3: 8)
CRDT.merge(counter1, counter2) # => %CRDT.GCounter{value: %{actor1: 5, actor2: 3, actor3: 8}}
```

### `CRDT.PNCounter`

A `CRDT.PNCounter` is used to process events that can increment or decrement the value.

#### Initializing

When initialized without starting values, the `CRDT.PNCounter` initial value is '0'.

``` elixir
counter = CRDT.PNCounter.new #=> %CRDT.PNCounter{pos: %{}, neg: %{}}
CRDT.value(counter) #=> 0
```

Initial values can be supplied as positive and negative actor => value maps.

``` elixir
counter = CRDT.PNCounter.new(pos: %{a: 1, b: 2}, neg: %{a: 8, b: 7}) 
CRDT.value(counter) #=> -12
```

#### Incrementing
Incrementing a `CRDT.PNCounter` is done via the `CRDT.PNCounter.increment/3` function.
Incrementing a pncounter will update only the `pos` actor => value map.
If no value is given, it will be updated by 1 by default.

``` elixir
pncounter = CRDT.PNCounter.new
pncounter = pncounter |> CRDT.PNCounter.increment(:a, 5) # => %CRDT.PNCounter{pos: %{a: 2}, neg: %{}}
pncounter = pncounter |> CRDT.PNCounter.increment(:a, 2) # => %CRDT.PNCounter{pos: %{a: 4}, neg: %{}}
CRDT.value(pncounter) # => 7
```

#### Decrementing
Decrementing a `CRDT.PNCounter` is done via the `CRDT.PNCounter.decrement/3` function.
Incrementing a pncounter will update only the `neg` actor => value map.
If no value is given, it will be updated by 1 by default.

``` elixir
pncounter = CRDT.PNCounter.new
pncounter = pncounter |> CRDT.PNCounter.decrement(:a, 5) # => %CRDT.PNCounter{pos: %{}, neg: %{a: 5}}
pncounter = pncounter |> CRDT.PNCounter.decrement(:a, 2) # => %CRDT.PNCounter{pos: %{}, neg: %{a: 7}}
CRDT.value(pncounter) # => -7
```

#### Merging
Merging two PNCounters preserves all actors in both, taking the total sum of all positive and negative values.

``` elixir
pncounter1 = CRDT.PNCounter.new |> CRDT.PNCounter.increment(actor1: 5, actor2: 3)
pncounter2 = CRDT.PNCounter.new |> CRDT.PNCounter.decrement(actor1: 5, actor3: 3)
merged = CRDT.merge(pncounter1, pncounter2) # => %CRDT.PNCounter{value: %{actor1: 5, actor2: 3, actor3: 8}}
CRDT.value(merged) # => 0
```

### `CRDT.LWWRegister`

A `CRDT.LWWRegister` is a crdt used when we are interested in having the most recent information available (Least Write Wins).
It contains a value and the corresponding timestamp.

#### Initializing

When initialized without starting values, the `CRDT.LWWRegister` initial value is 'nil'.

``` elixir
register = CRDT.LWWRegister.new #=> %CRDT.LWWRegister{value: nil, timestamp: 1698400752943930708}
CRDT.value(counter) #=> nil
```

#### Updating

Updating a `CRDT.LWWRegister` is done via the `CRDT.LWWRegister.set/2` function.
This will update the value with the current system time.

``` elixir
register = CRDT.LWWRegister.new
register = register |> CRDT.LWWRegister.set("hello register") # => %CRDT.LWWRegister{value: "hello register", timestamp: 1700218890688914751}
CRDT.value(register) # => "hello register"
```

#### Merging

Merging two LWWRegisters will simply take the most recent value.

``` elixir
register1 = CRDT.LWWRegister.new |> CRDT.LWWRegister.set("hello")
register2 = CRDT.LWWRegister.new |> CRDT.LWWRegister.set("latest_hello")
merged = CRDT.merge(register1, register2)
CRDT.value(merged) # => "latest_hello"
```

### `CRDT.AWORMap`

A `CRDT.AWORMap` is used to store events in a key => value map. The values stored in an AWORMap are crdts themselves.
Merging strategy follows those of the crdts contained in the map.

#### Initializing
The value of a new map is an empty map.

``` elixir
map = CRDT.AWORMap.new
CRDT.value(map) #=> %{}
```
When initialized the `CRDT.AWORMap` has this structure:

``` elixir
%CRDT.AWORMap{
  keys: %CRDT.AWORSet{
    dot_kernel: %CRDT.DotKernel{
      dot_context: %CRDT.DotContext{version_vector: %{}, dot_cloud: []},
      entries: %{}
    }
  },
  entries: %{}
}
```

Inside `CRDT.DotKernel` are the operations performed on the map: which actor made the change, the number of operation and the value added.
Inside the outer entries there is the map keylist with the current values.

It's possible to put a crdt in the `CRDT.AWORMap` through the `CRDT.AWORMap.put/4` function.
It's necessary to specify the actor who make the change, the key under which the crdt will be stored and the crdt itself.

``` elixir
map = CRDT.AWORMap.new
map = map |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new())
CRDT.value(map) #=> %{key: 0}
```

#### Updating

Updating a `CRDT.AWORMap` is done via the `CRDT.AWORMap.update!/4` function.
It's possible to pass a function as an argument that will be applied as the updated value of `key`

``` elixir
map = CRDT.AWORMap.new
map = map |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new() |> CRDT.GCounter.inc(:a, 1))
CRDT.value(map) #=> %{key: 1}
map = map |> CRDT.AWORMap.update!(:a, :key, &(CRDT.GCounter.inc(&1, :a, 100)))
CRDT.value(map) #=> %{key: 101}
```

##### Update vs Update! 
- `CRDT.AWORMap.update!/4` if the given "key" is not present in the AWORMap, a `KeyError` exception is raised.
- `CRDT.AWORMap.update/5` if the given "key" is not present in the AWORMap, the default value is inserted as the crdt of `key`

#### Merging

Merging two AWORMaps uses the same merge strategies as their crdts stored inside them.

``` elixir
map1 = CRDT.AWORMap.new |> CRDT.AWORMap.put(:a, :key, CRDT.GCounter.new() |> CRDT.GCounter.inc(:a, 1))
map2 = CRDT.AWORMap.new |> CRDT.AWORMap.put(:a, :key2, CRDT.GCounter.new() |> CRDT.GCounter.inc(:a, 100))
merged_map = CRDT.merge(map1, map2)
CRDT.value(merged_map) #=> %{key: 100}
```

## Known issues and limitations

- Development of δ-crdts is still work in progress.
- [Remove](https://github.com/platogo/crdt/issues/8) operation in AWORSet gives unexpected results.

## Acknowledgments

Articles

- Bartosz Sypytkowski series: [An introduction to state-based CRDTs](https://www.bartoszsypytkowski.com/the-state-of-a-state-based-crdts/)
- [CRDT and order theory](https://www.youtube.com/watch?v=OOlnp2bZVRs) 

Papers

- Marc Shapiro original paper on [Conflict-free Replicated Data Types](https://inria.hal.science/hal-00932836/file/CRDTs_SSS-2011.pdf)

## License
[(Back to top)](#table-of-contents)

The library is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
