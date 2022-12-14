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
    defstruct [:repo, :query, :ttl, :batch_size, :poll_interval, :cold_polls]
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
      cold_polls: 0
    }

    schedule(0)

    {:ok, state}
  end

  @impl true
  def handle_info(:reap, %{poll_interval: poll_interval, cold_polls: cold_polls} = state) do
    new_state = reap(state)

    new_interval =
      case cold_polls do
        0 ->
          poll_interval

        _ ->
          poll_interval * cold_polls
      end

    schedule(new_interval)

    {:noreply, new_state}
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

    {deleted_count, _} =
      query
      |> where([record], record.inserted_at < ^date)
      |> repo.delete_all(limit: batch_size)

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

  defp schedule(0) do
    send(self(), :reap)
  end

  defp schedule(interval) do
    Process.send_after(self(), :reap, :timer.seconds(interval))
  end
end
