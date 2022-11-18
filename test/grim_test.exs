defmodule GrimTest do
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

  test "reaps a soul" do
    opts = [
      repo: Repo,
      query: Soul
    ]

    date =
      DateTime.utc_now()
      |> DateTime.add(-999_999, :second)
      |> DateTime.truncate(:second)

    {:ok, soul} =
      %Soul{inserted_at: date}
      |> Repo.insert()

    {:ok, pid} = GenServer.start_link(Reaper, opts)

    :sys.get_state(pid)

    count =
      Soul
      |> Repo.all()
      |> Enum.count()

    assert count == 0

    :ok
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

    {:ok, pid} = GenServer.start_link(Reaper, opts)
    :sys.get_state(pid)

    count =
      Soul
      |> Repo.all()
      |> Enum.count()

    assert count == 1
    :ok
  end
end
