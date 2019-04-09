use Mix.Config

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :info_log}, :console]

# configuration for the {LoggerFileBackend, :info_log} backend
config :logger, :info_log,
  path: "prod.log",
  level: :info
