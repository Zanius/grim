defmodule Grim.Reaper do
  use GenServer
  import Ecto.Query
  require Logger

  @moduledoc """
  Remove records that are older than the set ttl (default of 1 week). Reapers are initialized with these defaults

  * `:ttl` — 1 week (604,800 seconds)
  * `:batch_size` — 1000
  * `:poll_interval` — `10`
  """

  @defaults [
    ttl: 604_800,
    batch_size: 1000,
    poll_interval: 10
  ]

  defmodule State do
    defstruct [
      :repo,
      :query,
      :ttl,
      :batch_size,
      :poll_interval,
      :current_poll_interval,
      :cold_polls
    ]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl true
  def init(opts) do
    opts = Keyword.merge(@defaults, opts)

    state = %State{
      query: opts[:query],
      ttl: opts[:ttl],
      batch_size: opts[:batch_size],
      repo: opts[:repo],
      poll_interval: opts[:poll_interval],
      current_poll_interval: opts[:poll_interval],
      cold_polls: 0
    }

    schedule(0)

    {:ok, state}
  end

  @impl true
  def handle_info(
        :reap,
        %{
          current_poll_interval: current_poll_interval,
          poll_interval: poll_interval,
          cold_polls: cold_polls
        } = state
      ) do
    new_state = reap(state)

    new_interval =
      case cold_polls do
        0 ->
          poll_interval

        _ ->
          current_poll_interval * cold_polls
      end

    schedule(new_interval)

    {:noreply, %{new_state | current_poll_interval: new_interval}}
  end

  def reap(
        %{query: schema, ttl: ttl, batch_size: batch_size, repo: repo, cold_polls: cold_polls} =
          state
      )
      when is_atom(schema) do
    date =
      DateTime.utc_now()
      |> DateTime.add(-ttl, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()

    primary_keys = schema.__schema__(:primary_key)

    id_maps =
      schema
      |> where([record], record.inserted_at < ^date)
      |> select([record], map(record, ^primary_keys))
      |> limit(^batch_size)
      |> repo.all()

    ids = build_id_map(id_maps)

    {deleted_count, _} = delete(repo, schema, ids)

    cold_polls =
      case deleted_count do
        0 ->
          cold_polls + 1

        _ ->
          0
      end

    Logger.debug("Grim deleted #{deleted_count} records")

    %{state | cold_polls: cold_polls}
  end

  def reap(
        %{query: query, ttl: ttl, batch_size: batch_size, repo: repo, cold_polls: cold_polls} =
          state
      ) do
    date =
      DateTime.utc_now()
      |> DateTime.add(-ttl, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_naive()

    {_, schema} = query.from.source

    primary_keys = schema.__schema__(:primary_key)

    id_maps =
      query
      |> where([record], record.inserted_at < ^date)
      |> select([record], map(record, ^primary_keys))
      |> limit(^batch_size)
      |> repo.all()

    ids = build_id_map(id_maps)
    {deleted_count, _} = delete(repo, schema, ids)

    cold_polls =
      case deleted_count do
        0 ->
          cold_polls + 1

        _ ->
          0
      end

    Logger.info("Grim deleted #{deleted_count} records")

    %{state | cold_polls: cold_polls}
  end

  defp delete(_, _, ids) when ids == %{} do
    {0, nil}
  end

  defp delete(repo, schema, ids) do
    # build dynamic query in case of composite keys
    dynamics =
      Enum.reduce(ids, dynamic(true), fn {key, ids}, dynamic ->
        dynamic([r], field(r, ^key) in ^ids and ^dynamic)
      end)

    query =
      from(record in schema,
        where: ^dynamics
      )

    repo.delete_all(query)
  end

  # dynamically build a map of ids to build dynamic queries
  # this is really only necessary in the case of composite keys
  # input: [%{id1: 123, id2: 456}, %{id1: 321, id2: 654}]
  # output: %{id1: [123, 321], id2: 456, 654}
  defp build_id_map(ids) do
    Enum.reduce(ids, %{}, fn map, acc ->
      Enum.reduce(map, acc, fn {k, v}, sub_acc ->
        case acc[k] do
          nil -> Map.put(sub_acc, k, [v])
          _ -> Map.put(sub_acc, k, [v | acc[k]])
        end
      end)
    end)
  end

  defp schedule(0) do
    send(self(), :reap)
  end

  defp schedule(interval) do
    Process.send_after(self(), :reap, :timer.seconds(interval))
  end
end
