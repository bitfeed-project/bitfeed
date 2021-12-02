# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :dep_project, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:dep_project, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"

polling_interval = 1_000
histogram_stats  = ~w(min max mean 95 90)a
memory_stats     = ~w(atom binary ets processes total)a

config(
  :exometer_core,
  predefined: [
    {
      ~w(erlang memory)a,
      {:function, :erlang, :memory, [], :proplist, memory_stats},
      []
    },
    {
      ~w(erlang statistics)a,
      {:function, :erlang, :statistics, [:'$dp'], :value, [:run_queue]},
      []
    }
  ],
  report: [
    reporters: [{BitcoinStream.ExometerReportDash, []}],
    subscribers: [
      {
        BitcoinStream.ExometerReportDash,
        [:erlang, :memory], memory_stats, polling_interval, true
      },
      {
        BitcoinStream.ExometerReportDash,
        [:erlang, :statistics], :run_queue, polling_interval, true
      },
    ]
  ]
)
config(
  :elixometer,
  reporter: BitcoinStream.ExometerReportDash,
  env: Mix.env,
  metric_prefix: "bitfeed_dash",
  excluded_datapoints: [:ms_since_reset]
)
