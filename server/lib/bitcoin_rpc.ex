defmodule BitcoinStream.RPC do
  @moduledoc """
  GenServer for bitcoin rpc requests
  """
  use GenServer

  alias Plug.BasicAuth, as: BasicAuth

  def start_link(opts) do
    {port, opts} = Keyword.pop(opts, :port);
    {host, opts} = Keyword.pop(opts, :host);
    IO.puts("Starting Bitcoin RPC server on #{host} port #{port}")
    GenServer.start_link(__MODULE__, {host, port, nil, nil, []}, opts)
  end

  @impl true
  def init({host, port, status, _, listeners}) do
    # start node monitoring loop
    creds = rpc_creds();

    send(self(), :check_status);
    {:ok, {host, port, status, creds, listeners}}
  end

  defp notify_listeners([]) do
    true
  end
  defp notify_listeners([head | tail]) do
    GenServer.reply(head, :mempool_synced);
    notify_listeners(tail)
  end

  @impl true
  def handle_info(:check_status, {host, port, _status, creds, listeners}) do
    # poll Bitcoin Core for current status
    status = check_status({host, port, creds});
    case status do
      # if node is connected and finished with the initial block download
      {:ok, %{"initialblockdownload" => false}} ->
        # notify all listening processes
        notify_listeners(listeners);
        Process.send_after(self(), :check_status, 300 * 1000);
        {:noreply, {host, port, status, creds, []}}

      {:ok, %{"initialblockdownload" => true}} ->
        IO.puts("Bitcoin Core connected, waiting for initial block download");
        Process.send_after(self(), :check_status, 30 * 1000);
        {:noreply, {host, port, status, creds, listeners}}

      _ ->
        IO.puts("Waiting to connect to Bitcoin Core");
        Process.send_after(self(), :check_status, 10 * 1000);
        {:noreply, {host, port, status, creds, listeners}}
    end
  end

  @impl true
  def handle_call({:request, method, params}, _from, {host, port, status, creds, listeners}) do
    case make_request(host, port, creds, method, params) do
      {:ok, code, info} ->
        {:reply, {:ok, code, info}, {host, port, status, creds, listeners}}

      {:error, reason} ->
        {:reply, {:error, reason}, {host, port, status, creds, listeners}}

      error ->
        {:reply, error, {host, port, status, creds, listeners}}
    end
  end

  @impl true
  def handle_call(:get_node_status, _from, {host, port, status, creds, listeners}) do
    {:reply, status, {host, port, status, creds, listeners}}
  end

  @impl true
  def handle_call(:notify_on_ready, from, {host, port, status, creds, listeners}) do
    {:noreply, {host, port, status, creds, [from | listeners]}}
  end

  def notify_on_ready(pid) do
    GenServer.call(pid, :notify_on_ready, :infinity)
  end

  defp make_request(host, port, creds, method, params) do
    with  { user, pw } <- creds,
          {:ok, rpc_request} <- Jason.encode(%{method: method, params: params}),
          {:ok, %Finch.Response{body: body, headers: _headers, status: status}} <- Finch.build(:post, "http://#{host}:#{port}", [{"content-type", "application/json"}, {"authorization", BasicAuth.encode_basic_auth(user, pw)}], rpc_request) |> Finch.request(FinchClient),
          {:ok, %{"result" => info}} <- Jason.decode(body) do
      {:ok, status, info}
    else
      {:ok, status, _} ->
        IO.puts("RPC request #{method} failed with HTTP code #{status}")
        {:error, status}
      {:error, reason} ->
        IO.puts("RPC request #{method} failed");
        IO.inspect(reason)
        {:error, reason}
      err ->
        IO.puts("RPC request #{method} failed: (unknown reason)");
        IO.inspect(err);
        {:error, err}
    end
  end

  def request(pid, method, params) do
    GenServer.call(pid, {:request, method, params}, 30000)
  catch
    :exit, reason ->
      case reason do
        {:timeout, _} -> {:error, :timeout}

        _ -> {:error, reason}
      end

    error -> {:error, error}
  end

  def get_node_status(pid) do
    GenServer.call(pid, :get_node_status, 10000)
  end

  defp check_status({host, port, creds}) do
    case make_request(host, port, creds, "getblockchaininfo", []) do
      {:ok, 200, info} -> {:ok, info}

      {:ok, code, info} -> {:error, code, info}

      _ -> {:error}
    end
  end

  defp rpc_creds() do
    cookie_path = System.get_env("BITCOIN_RPC_COOKIE");
    rpc_user = System.get_env("BITCOIN_RPC_USER");
    rpc_pw = System.get_env("BITCOIN_RPC_PASS");
    cond do
      (rpc_user != nil && rpc_pw != nil)
        -> { rpc_user, rpc_pw }
      (cookie_path != nil)
        ->
          with {:ok, cookie} <- File.read(cookie_path),
               [ user, pw ] <- String.split(cookie, ":") do
            { user, pw }
          else
            {:error, reason} ->
              IO.puts("Failed to load bitcoin rpc cookie");
              IO.inspect(reason)
              :error
            err ->
              IO.puts("Failed to load bitcoin rpc cookie: (unknown reason)");
              IO.inspect(err);
              :error
          end
      true ->
        IO.puts("Missing bitcoin rpc credentials");
        :error
    end
  end
end
