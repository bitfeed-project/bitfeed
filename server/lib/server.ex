defmodule BitcoinStream.Server do
  use Application

  def start(_type, _args) do
    { socket_port, "" } = Integer.parse(System.get_env("PORT"));
    { zmq_tx_port, "" } = Integer.parse(System.get_env("BITCOIN_ZMQ_RAWTX_PORT"));
    { zmq_block_port, "" } = Integer.parse(System.get_env("BITCOIN_ZMQ_RAWBLOCK_PORT"));
    { rpc_port, "" } = Integer.parse(System.get_env("BITCOIN_RPC_PORT"));
    btc_host = System.get_env("BITCOIN_HOST");

    children = [
      { BitcoinStream.BlockData, [name: :block_data] },
      { BitcoinStream.Mempool, [name: :mempool] },
      BitcoinStream.Metrics.Probe,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: BitcoinStream.Router,
        options: [
          dispatch: dispatch(),
          port: socket_port
        ]
      ),
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.BitcoinStream
      ),
      BitcoinStream.Bridge.child_spec(host: btc_host, tx_port: zmq_tx_port, block_port: zmq_block_port)
    ]

    opts = [strategy: :one_for_one, name: BitcoinStream.Application]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
        [
          {"/ws/txs", BitcoinStream.SocketHandler, []},
          {"/ws/status", BitcoinStream.Metrics.SocketHandler, []},
          {:_, Plug.Cowboy.Handler, {BitcoinStream.Router, []}}
        ]
      }
    ]
  end
end
