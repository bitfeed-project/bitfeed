defmodule BitcoinStream.BlockData do
  @moduledoc """
  Block data module.

  Serves a copy of the latest block
  """
  use GenServer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock

  def start_link(opts) do
    IO.puts("Starting block data link")
    # load block.dat

    with {:ok, block_data} <- File.read("block.dat"),
         {:ok, block} <- BitcoinBlock.decode(block_data),
         {:ok, payload} <- Jason.encode(%{type: "block", block: block}) do
      GenServer.start_link(__MODULE__, {block, payload}, opts)
    else
      _ -> GenServer.start_link(__MODULE__, {nil, "null"}, opts)
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:block_id, _from, {block, json}) do
    case block do
      %{id: id} ->
        {:reply, id, {block, json}}
      _ -> {:reply, nil, {block, json}}
    end
  end

  @impl true
  def handle_call(:block, _from, {block, json}) do
    {:reply, block, {block, json}}
  end

  @impl true
  def handle_call(:json_block, _from, {block, json}) do
    {:reply, json, {block, json}}
  end

  @impl true
  def handle_cast({:block, block}, state) do
    with {:ok, json } <- Jason.encode(%{type: "block", block: block}) do
      IO.puts("Storing block data");
      {:noreply, {block, json}}
    else
      {:err, reason} ->
        IO.puts("Failed to json encode block data");
        IO.inspect(reason);
        {:noreply, state}
      _ ->
        IO.puts("Failed to json encode block data");
        {:noreply, state}
    end
  end

  def get_block_number() do
  end

end
