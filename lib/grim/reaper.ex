defmodule Grim.Reaper do
  use GenServer
  import Ecto.Query

  @moduledoc """
  Remove records that are older than the set ttl (default of 1 week)
  """

  @defaults [
    ttl: 604_800,
    batch_size: 1000,
    poll_interval: 10000
  ]

  defmodule State do
    defstruct [:repo, :query, :ttl, :batch_size, :poll_interval, :cold_polls]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  @impl true
  def init(opts) do
    opts = @defaults ++ opts

    state = %State{
      query: opts[:query],
      ttl: opts[:ttl],
      batch_size: opts[:batch_size],
      repo: opts[:repo],
      poll_interval: opts[:poll_interval],
      cold_polls: 0
    }

    {:ok, state, {:continue, :schedule}}
  end

  @impl true
  def handle_continue(
        :schedule,
        %{
          query: query,
          ttl: ttl,
          batch_size: batch_size,
          repo: repo,
          poll_interval: poll_interval,
          cold_polls: cold_polls
        } = state
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

    Process.send_after(self(), :schedule, poll_interval * cold_polls)
    {:noreply, %{state | cold_polls: cold_polls}}
  end
end
