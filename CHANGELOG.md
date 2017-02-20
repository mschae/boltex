# Changelog

## v0.2.0

* Enhancements
  * Better error handling. Bolt errors (connection or otherwise) should now
    return a somewhat descriptive `Boltex.Error`. Unsupported data formats
    in the PackStream encoder will raise a `Boltex.PackStream.EncodeError`.
* Fixes
  * Attempted to fix an error for larger payloads.

## v0.0.2

* Enhancements
  * Adds `Boltex.Bolt.ack_failur/2` to acknowledge failures as intended by the
    bolt protocol (thanks @vic).
* Fixes
  * Encodes floats (how have I missed that?!).
