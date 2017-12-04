# Changelog

## v0.4.0

- not backward compatible. The init function now returns additional info received from the server
- dependencies updates

## v0.3.0

* Fixes
  * Added decoding for large structures
* Improvements
  * Better `run_statement` (see below)
  * Added `Boltex.Bolt.reset/2,3` to
    [reset a connection](http://boltprotocol.org/v1/#message-reset).
  * Significantly better testing and code coverage.

### Backwards incompatible changes
* We improved `Boltex.Bolt.run_statement/3,5`: Instead of always running
  `SIG PULL` we are now waiting for the run statement to return ok. This
  causes the server to no longer emit `IGNORED` messages when a failure
  happened. `Boltex.Bolt.ack_failure/2,3` was adjusted accordingly

## v0.2.1

* Fixes
  * Another attempt to fix larger payloads - this time with a test so good
    change it actually works (thanks @adri).
  * More generic error handling for unknown transports (thanks @florinpatrascu).

## v0.2.0

* Enhancements
  * Better error handling. Bolt errors (connection or otherwise) should now
    return a somewhat descriptive `Boltex.Error`. Unsupported data formats
    in the PackStream encoder will raise a `Boltex.PackStream.EncodeError`.
* Fixes
  * Attempted to fix an error for larger payloads.

## v0.0.2

* Enhancements
  * Adds `Boltex.Bolt.ack_failure/2` to acknowledge failures as intended by the
    bolt protocol (thanks @vic).
* Fixes
  * Encodes floats (how have I missed that?!).
