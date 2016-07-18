defmodule Boltex.Mixfile do
  use Mix.Project

  def project do
    [app: :boltex,
     version: "0.0.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "An Elixir driver for Neo4J's bolt protocol.",
     package: package,
     deps: deps]
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
      {:ex_doc, "~> 0.13.0", only: [:dev]},
      {:mix_test_watch, "~> 0.2.6", only: [:dev, :test]},
    ]
  end

  defp package do
    [
      name: :boltex,
      files: ~w(lib README.md LICENSE),
      build_tools: [:hex],
      maintainers: ["Michael Schaefermeyer"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/mschae/boltex",
        "Docs"   => "https://hexdocs.pm/boltex"
      }
    ]
  end
end
