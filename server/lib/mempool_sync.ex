defmodule BitcoinStream.Mempool.Sync do
  use Task, restart: :transient

  alias BitcoinStream.Mempool, as: Mempool

  def start_link(args) do
    Task.start_link(__MODULE__, :run, args)
  end

  def run(_args) do
    Mempool.sync(:mempool)
  end
end
