use Mix.Config

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :debug_log}]

# configuration for the {LoggerFileBackend, :debug_log} backend
config :logger, :debug_log,
  path: "dev.log",
  level: :debug
