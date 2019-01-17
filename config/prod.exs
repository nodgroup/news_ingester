use Mix.Config

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [{LoggerFileBackend, :info_log}]

# configuration for the {LoggerFileBackend, :info_log} backend
config :logger, :info_log,
  path: "prod.log",
  level: :info

config :ex_aws,
       :dynamodb,
       scheme: "http://",
       host: "localhost",
       port: 8000,
       region: "us-east-1"
