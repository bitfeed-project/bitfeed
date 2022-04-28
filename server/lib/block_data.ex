Application.ensure_all_started(BitcoinStream.RPC)

require Logger

defmodule BitcoinStream.BlockData do
  @moduledoc """
  Block data module.

  Maintains a flat-file db of blocks (if enabled)
  Serves a cached copy of the latest block
  """
  use GenServer
  use Task, restart: :transient

  def start_link(opts) do
    Logger.info("Starting block data link");
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
  def handle_call({:json, {id, json}}, _from, _state) do
      {:reply, :ok, {id, json}}
  end

  def get_json_block(pid) do
    GenServer.call(pid, :json_block, 10000)
  end

  def get_block_id(pid) do
    GenServer.call(pid, :block_id, 10000)
  end

  def set_json_block(pid, block_id, json) do
    GenServer.call(pid, {:json, { block_id, json }}, 10000)
  end

  def clean_block(block) do
    {txs, value, fees} = clean_txs(block["tx"]);
    {:ok, [
      block["version"],
      block["hash"],
      block["height"],
      value,
      block["previousblockhash"],
      block["time"],
      block["bits"],
      block["size"],
      txs,
      fees
    ]}
  end

  defp clean_txs([], clean, value, fees) do
    {Enum.reverse(clean), value, fees}
  end
  defp clean_txs([tx | rest], clean, value, fees) do
    {cleantx, txvalue, txfee} = clean_tx(tx)
    clean_txs(rest, [cleantx | clean], value + txvalue, fees + txfee)
  end
  defp clean_txs(txs) do
    clean_txs(txs, [], 0, 0)
  end

  defp clean_tx(tx) do
    total_value = sum_output_values(tx["vout"]);
    outputs = clean_outputs(tx["vout"]);
    fee = if tx["fee"] != nil do round(tx["fee"] * 100000000) else 0 end
    {[
      tx["version"],
      tx["txid"],
      fee,
      total_value,
      tx["vsize"],
      length(tx["vin"]),
      outputs
    ], total_value, fee}
  end

  defp clean_outputs([], clean) do
    Enum.reverse(clean)
  end
  defp clean_outputs([out | rest], clean) do
    clean_outputs(rest, [clean_output(out) | clean])
  end
  defp clean_outputs(outputs) do
    clean_outputs(outputs, [])
  end

  defp clean_output(output) do
    [
      round(output["value"] * 100000000),
      output["scriptPubKey"]["hex"]
    ]
  end

  defp sum_output_values([], value) do
    value
  end
  defp sum_output_values([out|rest], value) do
    sum_output_values(rest, value + round(out["value"] * 100000000))
  end
  defp sum_output_values(outputs) do
    sum_output_values(outputs, 0)
  end
end
