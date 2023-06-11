defmodule Grim.ReaperSupervisor do
  alias Grim.Reaper
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    children =
      Enum.map(opts[:reapers], fn child ->
        transform_child(child, opts[:repo])
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  # converts different init options into child specs
  defp transform_child(child, repo) when is_atom(child) do
    {Reaper, [query: child, repo: repo]}
  end

  defp transform_child({Reaper, reaper_opts}, repo) do
    {Reaper, Keyword.merge(reaper_opts, repo: repo)}
  end

  defp transform_child({schema, reaper_opts}, repo) do
    {Reaper, Keyword.merge(reaper_opts, query: schema, repo: repo)}
  end
end
