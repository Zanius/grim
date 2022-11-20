defmodule GrimTest do
  alias Grim.Reaper
  alias Grim.ReaperSupervisor
  alias Grim.Test.Souls.Soul
  alias Grim.Test.Repo
  import Ecto.Query

  use ExUnit.Case, async: false

  setup do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Grim.Test.Repo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  test "reaps a soul" do
    opts = [
      repo: Repo,
      query: Soul,
      poll_interval: 0
    ]

    date =
      DateTime.utc_now()
      |> DateTime.add(-999_999, :second)
      |> DateTime.truncate(:second)

    %Soul{inserted_at: date}
    |> Repo.insert()

    {:ok, pid} = Reaper.start_link(opts)

    :sys.get_state(pid)

    count =
      Soul
      |> Repo.all()
      |> Enum.count()

    assert count == 0
  end

  test "reaps a soul with a specific query" do
    date =
      DateTime.utc_now()
      |> DateTime.add(-999_999, :second)
      |> DateTime.truncate(:second)

    {:ok, %{soul_id: unreaped_soul_id}} = Repo.insert(%Soul{inserted_at: date})

    {:ok, %{soul_id: reaped_soul_id}} = Repo.insert(%Soul{inserted_at: date})

    query =
      from(s in Soul,
        where: s.soul_id == ^reaped_soul_id
      )

    opts = [
      repo: Repo,
      query: query,
      poll_interval: 0
    ]

    {:ok, pid} = Reaper.start_link(opts)

    :sys.get_state(pid)

    assert Repo.get!(Soul, unreaped_soul_id)

    count =
      Soul
      |> Repo.all()
      |> Enum.count()

    assert count == 1
  end

  test "does not reap a soul that's not old enough, and increments cold poll correctly" do
    opts = [
      repo: Repo,
      query: Soul
    ]

    date =
      DateTime.utc_now()
      |> DateTime.add(0, :second)
      |> DateTime.truncate(:second)

    %Soul{inserted_at: date}
    |> Repo.insert()

    {:ok, pid} = GenServer.start(Reaper, opts)

    %{cold_polls: 1} = :sys.get_state(pid)

    count =
      Soul
      |> Repo.all()
      |> Enum.count()

    assert count == 1
  end

  describe "Reaper supervisor start_link/2" do
    test "starts with explicit Reaper child_spec" do
      supervisor_opts = [
        repo: Repo,
        reapers: [{Reaper, [query: Soul, poll_interval: 100]}]
      ]

      {:ok, pid} = ReaperSupervisor.start_link(supervisor_opts)

      [{_, child, _, _}] = Supervisor.which_children(pid)

      %{poll_interval: 100} = :sys.get_state(child)
    end

    test "starts with schema as first element of tuple" do
      supervisor_opts = [
        repo: Repo,
        reapers: [{Soul, [ttl: 10]}]
      ]

      {:ok, pid} = ReaperSupervisor.start_link(supervisor_opts)

      [{_, child, _, _}] = Supervisor.which_children(pid)
      %{ttl: 10} = :sys.get_state(child)
    end

    test "starts with schema alone" do
      supervisor_opts = [
        repo: Repo,
        reapers: [Soul]
      ]

      {:ok, pid} = ReaperSupervisor.start_link(supervisor_opts)

      [{Reaper, child, _, _}] = Supervisor.which_children(pid)

      :sys.get_state(child)
    end
  end
end
