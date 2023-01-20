defmodule Grim.Test.Repo do
  use Ecto.Repo,
    otp_app: :grim,
    adapter: Ecto.Adapters.Postgres,
    priv: "test/support/repo"
end
