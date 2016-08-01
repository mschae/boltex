# Boltex

Elixir implementation of the Bolt protocol and corresponding PackStream
protocol. Both is being used by Neo4J.

*Warning: This is currently WIP and only in the wild to gather feedback!*

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

## Try it out!

```elixir
Boltex.test 'localhost', 7687, "MATCH (n) RETURN n"
```

## Todo

- [x] PackStream decoding
- [x] PackStream encoding
- [x] Bolt message receiving
- [x] Bolt message sending
- [x] Auth
- [ ] Transport adapter (e.g. plain `:gen_tcp`, `DBConnection`, ...)
- [ ] Handle failures gracefully
- [ ] SSL

## License

Copyright 2016 Michael Schaefermeyer

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
