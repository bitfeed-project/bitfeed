import Config

config :logger, :console,
  format: "$time $metadata[$level] $levelpad$message\n"
