Application.ensure_all_started(BitcoinStream.RPC)

defmodule BitcoinStream.BlockData do
  @moduledoc """
  Block data module.

  Serves a cached copy of the latest block
  """
  use GenServer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock

  def start_link(opts) do
    IO.puts("Starting block data link")
    # load block

    with {:ok, json} <- File.read("data/last_block.json"),
         {:ok, %{"id" => id}} <- Jason.decode(json) do
      GenServer.start_link(__MODULE__, {id, json}, opts)
    else
      _ -> GenServer.start_link(__MODULE__, {nil, "null"}, opts)
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:block_id, _from, {id, json}) do
    {:reply, id, {id, json}}
  end

  @impl true
  def handle_call(:json_block, _from, {id, json}) do
    {:reply, json, {id, json}}
  end

  @impl true
  def handle_cast({:json, {id, json}}, _state) do
      {:noreply, {id, json}}
  end
end
