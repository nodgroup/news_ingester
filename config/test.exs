use Mix.Config

config :news_ingester,
  api_username: "placeholder",
  api_password: "placeholder",
  key: "value"

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :debug_log}]

# configuration for the {LoggerFileBackend, :debug_log} backend
config :logger, :debug_log,
  path: "debug.log",
  level: :debug
