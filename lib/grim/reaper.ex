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
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
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

    Process.send_after(self(), :reap, opts[:poll_interval])

    {:ok, state}
  end

  @impl true
  def handle_info(
        :reap,
        %{
          poll_interval: poll_interval,
          cold_polls: cold_polls
        } = state
      ) do
    IO.inspect("getting reaped")
    new_state = reap(state)

    new_interval =
      case cold_polls do
        0 ->
          poll_interval

        _ ->
          poll_interval * cold_polls
      end

    Process.send_after(self(), :reap, new_interval)

    {:noreply, new_state}
  end

  def reap(
        %{
          query: query,
          ttl: ttl,
          batch_size: batch_size,
          repo: repo,
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
      |> IO.inspect(label: "REEAP")

    cold_polls =
      case deleted_count do
        0 ->
          cold_polls + 1

        _ ->
          0
      end

    IO.inspect("hello!!!")

    %{state | cold_polls: cold_polls}
  end
end
