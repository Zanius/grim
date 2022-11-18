import Config

# config :grim, Grim.Test.Repo,
#   database: "grim_test",
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost"

config :grim, ecto_repos: [Grim.Test.Repo]
