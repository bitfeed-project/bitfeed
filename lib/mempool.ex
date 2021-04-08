Application.ensure_all_started(:hackney)

defmodule BitcoinStream.Mempool do
  @moduledoc """
  Agent for retrieving and maintaining mempool info (primarily tx count)
  """
  use Agent

  @doc """
  Start a new mempool tracker,
  connecting to a bitcoin node at RPC `port` for ground truth data
  """
  def start_link(opts) do
    {port, opts} = Keyword.pop(opts, :port);
    IO.puts("Starting mempool agent on port #{port}");
    case Agent.start_link(fn -> %{count: 0, port: port} end, opts) do
      {:ok, pid} ->
        sync(pid);
        {:ok, pid}

      result -> result
    end
  end

  def getPort(pid) do
    Agent.get(pid, &Map.get(&1, :port))
  end

  def set(pid, n) do
    Agent.update(pid, &Map.update(&1, :count, 0, fn(_) -> n end))
  end

  def get(pid) do
    Agent.get(pid, &Map.get(&1, :count))
  end

  def increment(pid) do
    Agent.update(pid, &Map.update(&1, :count, 0, fn(x) -> x + 1 end))
  end

  def decrement(pid) do
    Agent.update(pid, &Map.update(&1, :count, 0, fn(x) -> x - 1 end))
  end

  def add(pid, n) do
    Agent.update(pid, &Map.update(&1, :count, 0, fn(x) -> x + n end))
  end

  def subtract(pid, n) do
    Agent.update(pid, &Map.update(&1, :count, 0, fn(x) -> x - n end))
  end

  def sync(pid) do
    port = getPort(pid);
    user = System.get_env("BITCOIN_RPC_USER");
    pass = System.get_env("BITCOIN_RPC_PASS");
    IO.puts("Syncing mempool with bitcoin node on port #{port}");
    with  {:ok, rpc_request} <- Jason.encode(%{method: "getmempoolinfo", params: [], request_id: 0}),
          {:ok, 200, _headers, body_ref} <- :hackney.request(:post, "http://localhost:#{port}", [{"content-type", "application/json"}], rpc_request, [basic_auth: {user, pass}]),
          {:ok, body} <- :hackney.body(body_ref),
          {:ok, %{"result" => info}} <- Jason.decode(body),
          %{"size" => pool_size} <- info do
      IO.puts("Synced pool: size = #{pool_size}");
      set(pid, pool_size)
    else
      {:error, reason} ->
        IO.puts("Pool sync failed");
        IO.inspect(reason)
        :error
      _ ->
        IO.puts("Pool sync failed: (unknown reason)");
        :error
    end
  end
end
