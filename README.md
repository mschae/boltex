# Boltex
[![Build Status](https://travis-ci.org/mschae/boltex.svg?branch=master)](https://travis-ci.org/mschae/boltex)
[![Inline docs](http://inch-ci.org/github/mschae/boltex.svg?branch=master)](http://inch-ci.org/github/mschae/boltex)


Elixir implementation of the Bolt protocol and corresponding PackStream
protocol. Both is being used by Neo4J.

This is a very bare-bone protocol implementation. Error handling, acknowledging
errors, recovering sessions etc. has to be implemented upstream.

*Warning: This is currently WIP and only in the wild to gather feedback!*

If you want to use Boltex in production I highly recommend using connection
pooling. You can either use the feature-rich
[Bolt.Sips](https://github.com/florinpatrascu/bolt_sips) or check out the
[example DBConnection implementation](https://github.com/mschae/boltex_db_connection).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add boltex to your list of dependencies in `mix.exs`:

        def deps do
          [{:boltex, "~> a.b.c"}]
        end

  2. Ensure boltex is started before your application:

        def application do
          [applications: [:boltex]]
        end

## Try it out!

```elixir
Boltex.test 'localhost', 7687, "MATCH (n) RETURN n"
```

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
