defmodule BitcoinStream.Mempool do
  @moduledoc """
  Agent for retrieving and maintaining mempool info (primarily tx count)
  """
  use Agent

  alias BitcoinStream.RPC, as: RPC

  @doc """
  Start a new mempool tracker,
  connecting to a bitcoin node at RPC `host:port` for ground truth data
  """
  def start_link(opts) do
    IO.puts("Starting mempool agent");
    case Agent.start_link(fn -> %{count: 0} end, opts) do
      {:ok, pid} ->
        sync(pid);
        {:ok, pid}

      result -> result
    end
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
    IO.puts("Syncing mempool");
    with  {:ok, %{"size" => pool_size}} <- RPC.request(:rpc, "getmempoolinfo", []) do
      IO.puts("Synced pool: size = #{pool_size}");
      set(pid, pool_size)
    else
      {:error, reason} ->
        IO.puts("Pool sync failed");
        IO.inspect(reason)
        :error
      err ->
        IO.puts("Pool sync failed: (unknown reason)");
        IO.inspect(err);
        :error
    end
  end

end
