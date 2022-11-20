defmodule GrimTest do
  alias Task.Supervisor
  alias Grim.ReaperSupervisor
  alias Grim.Reaper
  alias Grim.Test.Souls.Soul
  alias Grim.Test.Repo

  import Ecto.Query

  use ExUnit.Case, async: false

  setup context do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Grim.Test.Repo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  test "Reaper initializes correctly" do
    opts = [
      repo: Repo,
      query: Soul
    ]

    {:ok, pid} = GenServer.start_link(Reaper, opts)

    :sys.get_state(pid)

    :ok
  end

  describe "Reaper.reap/1" do
    test "reaps a soul older than the default ttl" do
      opts = [
        repo: Repo,
        query: Soul
      ]

      {:ok, state, _} = Reaper.init(opts)

      date =
        DateTime.utc_now()
        |> DateTime.add(-999_999, :second)
        |> DateTime.truncate(:second)

      {:ok, soul} =
        %Soul{inserted_at: date}
        |> Repo.insert()

      Reaper.reap(state)

      count =
        Soul
        |> Repo.all()
        |> Enum.count()

      assert count == 0
    end

    test "reap" do
      opts = [
        repo: Repo,
        query: Soul,
        poll_interval: 0
      ]

      date =
        DateTime.utc_now()
        |> DateTime.add(-999_999, :second)
        |> DateTime.truncate(:second)

      {:ok, soul} =
        %Soul{inserted_at: date}
        |> Repo.insert()

      {:ok, pid} = GenServer.start(Reaper, opts)

      state = :sys.get_state(pid)

      count =
        Soul
        |> Repo.all()
        |> Enum.count()

      assert count == 0
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

      {:ok, soul} =
        %Soul{inserted_at: date}
        |> Repo.insert()

      {:ok, pid} = GenServer.start(Reaper, opts)

      state = :sys.get_state(pid)

      count =
        Soul
        |> Repo.all()
        |> Enum.count()

      assert count == 1
    end
  end

  describe "Reaper supervisor start_link/2" do
    setup do
      date =
        DateTime.utc_now()
        |> DateTime.add(-999_999, :second)
        |> DateTime.truncate(:second)

      {:ok, soul} =
        %Soul{inserted_at: date}
        |> Repo.insert()

      {:ok, date: date, soul: soul}
    end

    test "starts with explicit Reaper child_spec", %{date: date, soul: soul} do
      supervisor_opts = [
        repo: Repo,
        reapers: [{Reaper, [query: Soul, ttl: 10]}]
      ]

      {:ok, pid} = Supervisor.start_link(ReaperSupervisor, supervisor_opts)

      [{_, reaper_pid, _, _}] = Supervisor.which_children(pid) |> IO.inspect()

      :sys.get_state(reaper_pid)
      count = Soul |> Repo.all() |> Enum.count()
    end

    test "starts with schema as first element of tuple", %{date: date, soul: soul} do
      supervisor_opts = [
        repo: Repo,
        reapers: [{Soul, [ttl: 10]}]
      ]

      {:ok, pid} = Supervisor.start_link(ReaperSupervisor, supervisor_opts)

      [{_, reaper_pid, _, _}] = Supervisor.which_children(pid) |> IO.inspect()

      :sys.get_state(reaper_pid)
      count = Soul |> Repo.all() |> Enum.count()
    end

    test "starts with schema alone", %{date: date, soul: soul} do
      supervisor_opts = [
        repo: Repo,
        reapers: [Soul]
      ]

      {:ok, pid} = Supervisor.start_link(ReaperSupervisor, supervisor_opts)

      [{_, reaper_pid, _, _}] = Supervisor.which_children(pid) |> IO.inspect()

      :sys.get_state(reaper_pid)
      count = Soul |> Repo.all() |> Enum.count()
    end
  end
end
