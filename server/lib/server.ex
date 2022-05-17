require Logger

defmodule BitcoinStream.Server do
  use Application

  def start(_type, _args) do
    { socket_port, "" } = Integer.parse(System.get_env("PORT") || "5001");
    { zmq_tx_port, "" } = Integer.parse(System.get_env("BITCOIN_ZMQ_RAWTX_PORT") || "28333");
    { zmq_block_port, "" } = Integer.parse(System.get_env("BITCOIN_ZMQ_RAWBLOCK_PORT") || "28332");
    { zmq_sequence_port, "" } = Integer.parse(System.get_env("BITCOIN_ZMQ_SEQUENCE_PORT") || "28334");
    { rpc_port, "" } = Integer.parse(System.get_env("BITCOIN_RPC_PORT") || "8332");
    { rpc_pools, "" } = Integer.parse(System.get_env("RPC_POOLS") || "1");
    { rpc_pool_size, "" } = Integer.parse(System.get_env("RPC_POOL_SIZE") || "16");
    log_level = System.get_env("LOG_LEVEL");
    btc_host = System.get_env("BITCOIN_HOST");
    indexed = System.get_env("INDEXED")

    case log_level do
      "debug" ->
        Logger.configure(level: :debug);

      "error" ->
        Logger.configure(level: :error);

      _ ->
        Logger.configure(level: :info);
    end

    children = [
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.BitcoinStream
      ),
      {Finch,
       name: FinchClient,
       pools: %{
         :default => [size: rpc_pool_size, count: rpc_pools],
         "http://#{btc_host}:#{rpc_port}" => [size: rpc_pool_size, count: rpc_pools]
       }},
      { BitcoinStream.RPC, [host: btc_host, port: rpc_port, name: :rpc] },
      { BitcoinStream.BlockData, [name: :block_data] },
      { BitcoinStream.Index.Spend, [name: :spends, indexed: indexed]},
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: BitcoinStream.Router,
        options: [
          dispatch: dispatch(),
          port: socket_port
        ]
      ),
      %{
        id: BitcoinStream.Bridge,
        start: {Supervisor, :start_link, [
          [
            { BitcoinStream.Mempool, [name: :mempool] },
            { BitcoinStream.Mempool.Sync, [name: :mempool_sync] },
            BitcoinStream.Bridge.Tx.child_spec(host: btc_host, port: zmq_tx_port),
            BitcoinStream.Bridge.Block.child_spec(host: btc_host, port: zmq_block_port),
            BitcoinStream.Bridge.Sequence.child_spec(host: btc_host, port: zmq_sequence_port),
          ],
          [strategy: :one_for_all]
        ]},
        type: :supervisor,
        restart: :permanent
      }
    ]
    version()
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

  defp version() do
    {:ok, vsn} = :application.get_key(:bitcoin_stream, :vsn)
    splash_text =
      """
      ####################################################
      ###            BITFEED VERSION IS: v#{vsn}       ###
      ####################################################
      """
    IO.puts(splash_text)
  end
end
