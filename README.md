# Boltex

Elixir implementation of the Bolt protocol and corresponding PackStream
protocol. Both is being used by Neo4J.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add boltex to your list of dependencies in `mix.exs`:

        def deps do
          [{:boltex, "~> 0.0.1"}]
        end

  2. Ensure boltex is started before your application:

        def application do
          [applications: [:boltex]]
        end

## Todo

- [x] PackStream decoding
- [x] PackStream encoding
- [x] Bolt message receiving
- [x] Bolt message sending
- [ ] Auth
- [ ] Transport adapter (e.g. plain `:gen_tcp`, `DBConnection`, ...)
- [ ] Handle failures gracefully
