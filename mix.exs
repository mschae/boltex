defmodule Boltex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :boltex,
      version: "0.4.0",
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: "An Elixir driver for Neo4J's bolt protocol.",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      #mod: {Boltex, []},
      applications: [:logger]
   ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: [:dev]},
      {:excoveralls, "~> 0.7.5", only: [:test]},
      {:inch_ex, "~> 0.5.6", only: [:docs]},
      {:mix_test_watch, "~> 0.5.0", only: [:dev, :test]},
    ]
  end

  defp package do
    [
      name: :boltex,
      files: ~w(mix.exs lib README.md LICENSE),
      build_tools: [:hex],
      maintainers: ["Michael Schaefermeyer"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/mschae/boltex",
        "Docs"   => "https://hexdocs.pm/boltex"
      }
    ]
  end

  defp preferred_cli_env do
    [
      "coveralls": :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test
    ]
  end
end
