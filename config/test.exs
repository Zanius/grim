import Config

config :grim, Grim.Test.Repo,
  database: "grim_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

config :grim, ecto_repos: [Grim.Test.Repo]
