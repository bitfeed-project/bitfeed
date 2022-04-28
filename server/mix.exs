defmodule BitcoinStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitcoin_stream,
      version: "2.2.1",
      elixir: "~> 1.10",
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
      extra_applications: [:logger, :corsica]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:mix_systemd, "~> 0.7"},
      # {:mix_systemd, "~> 0.7"},
      {:chumak, "~> 1.3"},
      # {:bitcoinex, "~> 0.1.0"},
      # {:bitcoinex, git: "git@github.com:mononaut/bitcoinex.git", tag: "master"},
      {:bitcoinex, path: "./bitcoinex", override: true},
      {:finch, "~> 0.10"},
      {:cowboy, "~> 2.7"},
      {:plug, "~> 1.13"},
      {:corsica, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:rocksdb, "~> 1.6"}
    ]
  end
end
