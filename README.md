# Grim

Grim is a pruning library that periodically destroys stale records that are no longer useful.

After installing Grim, add the `Grim.ReaperSupervisor` to your supervision tree with a list of schemas or queries
that you would like to delete.


```elixir
  grim_config = [
    repo: MyApp.Repo,
    reapers: [Soul, Chaff, Spirit]
  ]

  children =
  [
    {Grim.ReaperSupervisor, grim_config}
  ]
```


The reaper supervisor can be initialized in 4 different ways.

1. A list of Schemas, if you would like to use the default pruning values

```elixir
  grim_config = [
    repo: Repo,
    reapers: [Soul, Chaff, Spirit]
  ]
```

2. A list of Schema tuples with configuration options
```elixir
  grim_config = [
    repo: Repo,
    reapers: [{Soul, [ttl: 10_000]}, {Chaff, [poll_interval: 100]}, {Spirit, [batch_size: 10_000]}]
  ]
```

3. With explicit reaper child specs
```elixir
  grim_config = [
    repo: Repo,
    reapers: [{Reaper, [query: Soul, poll_interval: 100]}, {Reaper, [query: Chaff]}, {Reaper, [batch_size: 100]}]
  ]
```

4. Or a combination of all of the above
```elixir
  grim_config = [
    repo: Repo,
    reapers: [{Reaper, [query: Soul, poll_interval: 100]}, Chaff, {Spirit, [batch_size: 10_000]}]
  ]
```


The following configurations are available
```
:batch_size -> Number of records deleted at a time, defaults to 1000
:poll_interval -> How often grim should check for records to delete, defaults to 10 seconds
:ttl -> Number of seconds a record needs to be before deletion, defaults to 1 week
:query -> An ecto Schema module name or an ecto query (grim dynamically fetches primary keys, including composite keys)
```




## Installation

Install by adding `grim` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:grim, "~> 0.3.4"}
  ]
end
```

Docs can be found at <https://hexdocs.pm/grim>
