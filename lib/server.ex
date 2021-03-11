defmodule BitcoinStream.Server do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: BitcoinStream.Router,
        options: [
          dispatch: dispatch(),
          port: 4000
        ]
      ),
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.BitcoinStream
      ),
      BitcoinStream.Bridge.child_spec(port: 29000)
    ]

    opts = [strategy: :one_for_one, name: BitcoinStream.Application]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
        [
          {"/ws/txs", BitcoinStream.SocketHandler, []},
          {:_, Plug.Cowboy.Handler, {BitcoinStream.Router, []}}
        ]
      }
    ]
  end
end
