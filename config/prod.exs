use Mix.Config

config :logger,
  compile_time_purge_level: :warn

config :boltex,
  log: false,
  log_hex: false
