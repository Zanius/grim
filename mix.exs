defmodule Grim.MixProject do
  use Mix.Project

  @github "https://github.com/zanius/grim"
  @version "0.1.0"

  def project do
    [
      app: :grim,
      name: "Grim",
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      homepage: @github,
      package: package(),
      description: description(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Grim.Application, []}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:vapor, "~> 0.10"},
      {:ecto_sql, "~> 3.8.1"},
      {:postgrex, ">= 0.0.0"}
    ]
  end

  defp description do
    "Grim is a pruning library that periodically destroys stale records that are no longer useful."
  end

  defp package do
    [
      maintainers: ["Zane Brown"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      source_url: @github,
      extras: ["README.md"],
      source_url_pattern: "#{@github}/blob/master/%{path}#L%{line}"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
