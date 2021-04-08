defmodule BitcoinStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitcoin_stream,
      version: "1.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        prod: [
          include_executables_for: [:unix],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BitcoinStream.Server, []},
      extra_applications: [:logger, :elixometer]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:mix_systemd, "~> 0.7"},
      # {:mix_systemd, "~> 0.7"},
      {:chumak, github: "zeromq/chumak"},
      # {:bitcoinex, "~> 0.1.0"},
      # {:bitcoinex, git: "git@github.com:mononaut/bitcoinex.git", tag: "master"},
      {:bitcoinex, path: "../bitcoinex", override: true},
      {:hackney, "~> 1.15"},
      {:cowboy, "~> 2.4"},
      {:plug, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:elixometer, "~> 1.4"}
    ]
  end
end
