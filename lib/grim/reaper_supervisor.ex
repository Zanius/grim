defmodule Grim.ReaperSupervisor do
  alias Grim.Reaper
  use GenServer

  def start_link(queries) do
    GenServer.start_link(__MODULE__, queries, [])
  end

  @impl true
  def init(queries) do
    children =
      Enum.map(queries, fn query ->
        {Reaper, [query: query]}
      end)

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, children}
  end
end
