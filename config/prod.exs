use Mix.Config

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :info_log}]

# configuration for the {LoggerFileBackend, :info_log} backend
config :logger, :info_log,
  path: "info.log",
  level: :info
