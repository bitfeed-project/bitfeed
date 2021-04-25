Application.ensure_all_started(:hackney)

defmodule BitcoinStream.Donations.Lightning do
  @moduledoc """
  Module for handling Bitcoin lightning invoices for donations
  """

  use GenServer

  alias BitcoinStream.Protocol.Block, as: BitcoinBlock
  alias BitcoinStream.Protocol.Transaction, as: BitcoinTx
  alias BitcoinStream.Mempool, as: Mempool

  def child_spec() do
    %{
      id: BitcoinStream.Donations.Lightning,
      start: {BitcoinStream.Donations.Lightning, :start_link, []}
    }
  end

  @doc """
  Start a new lightning handler agent
  """
  def start_link() do
    IO.puts("Starting Lightning Handler")
    GenServer.start_link(__MODULE__, %{})
  end

  def init(arg) do
    {:ok, arg}
  end

  def get_invoice(id) do
    btcpay_root = System.get_env("BTCPAY_ROOT");
    btcpay_store_id = System.get_env("BTCPAY_STORE_ID")
    api_route = "#{btcpay_root}/api/v1/stores/#{btcpay_store_id}/lightning/btc/invoices/#{id}"
    btcpay_key = System.get_env("BTCPAY_KEY");
    IO.puts("Getting Lightning invoice #{id}");
    with  {:ok, 200, _headers, body_ref} <- :hackney.request(
              :get,
              api_route,
              [
                {"authorization", "token #{btcpay_key}"}
              ]
            ),
          {:ok, body} <- :hackney.body(body_ref) do

      {:ok, body}
    else
      {:error, reason} ->
        IO.puts("Lightning API failed");
        IO.inspect(reason)
        :error
      _ ->
        IO.puts("Lightning API failed: (unknown reason)");
        :error
    end
  end

  def create_invoice(amount) do
    millisatoshis = amount * 1000
    btcpay_root = System.get_env("BTCPAY_ROOT");
    btcpay_store_id = System.get_env("BTCPAY_STORE_ID")
    api_route = "#{btcpay_root}/api/v1/stores/#{btcpay_store_id}/lightning/btc/invoices"
    btcpay_key = System.get_env("BTCPAY_KEY");
    IO.puts("Creating Lightning invoice for #{amount}");
    with  {:ok, api_request} <- Jason.encode(%{
              amount: "#{millisatoshis}",
              description: "Bitfeed donation",
              expiry: 600
            }),
          {:ok, 200, _headers, body_ref} <- :hackney.request(
              :post,
              api_route,
              [
                {"authorization", "token #{btcpay_key}"},
                {"content-type", "application/json"}
              ],
              api_request
            ),
          {:ok, body} <- :hackney.body(body_ref) do

      {:ok, body}
    else
      {:error, reason} ->
        IO.puts("Lightning API failed");
        IO.inspect(reason)
        :error
      _ ->
        IO.puts("Lightning API failed: (unknown reason)");
        :error
    end
  end
end
