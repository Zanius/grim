defmodule Grim.ReaperSupervisor do
  alias Grim.Reaper
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(queries) do
    children =
      Enum.map(queries, fn query ->
        {Reaper, [query: query]}
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
