require Logger

defmodule BitcoinStream.RPC do
  @moduledoc """
  GenServer for bitcoin rpc requests
  """
  use GenServer

  alias Plug.BasicAuth, as: BasicAuth

  def start_link(opts) do
    {port, opts} = Keyword.pop(opts, :port);
    {host, opts} = Keyword.pop(opts, :host);
    Logger.info("Starting Bitcoin RPC server on #{host} port #{port}")
    GenServer.start_link(__MODULE__, {host, port, nil, nil, [], %{}}, opts)
  end

  @impl true
  def init({host, port, status, _, listeners, inflight}) do
    # start node monitoring loop
    creds = rpc_creds();

    send(self(), :check_status);
    {:ok, {host, port, status, creds, listeners, inflight}}
  end

  defp notify_listeners([]) do
    true
  end
  defp notify_listeners([head | tail]) do
    GenServer.reply(head, :mempool_synced);
    notify_listeners(tail)
  end

  @impl true
  def handle_info(:check_status, {host, port, status, creds, listeners, inflight}) do
    case async_request("getblockchaininfo", [], host, port, creds) do
      {:ok, task_ref} ->
        {:noreply, {host, port, status, creds, listeners, Map.put(inflight, task_ref, :status)}}

      :error ->
        Logger.info("Waiting to connect to Bitcoin Core");
        Process.send_after(self(), :check_status, 10 * 1000);
        {:noreply, {host, port, status, creds, listeners, inflight}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {host, port, status, creds, listeners, inflight}) do
    {_, inflight} = Map.pop(inflight, ref);
    {:noreply, {host, port, status, creds, listeners, inflight}}
  end

  @impl true
  def handle_info({ref, result}, {host, port, status, creds, listeners, inflight}) do
    if Enum.count(inflight) > 2 do
      Logger.debug("#{Enum.count(inflight)} rpc requests inflight");
    end
    case Map.pop(inflight, ref) do
      {nil, inflight} ->
        {:noreply, {host, port, status, creds, listeners, inflight}}

      {:status, inflight} ->
        case result do
          # if node is connected and finished with the initial block download
          {:ok, 200, %{"initialblockdownload" => false}} ->
            # notify all listening processes
            Logger.info("Bitcoin Core connected and synced");
            notify_listeners(listeners);
            Process.send_after(self(), :check_status, 300 * 1000);
            {:noreply, {host, port, :ok, creds, [], inflight}}

          {:ok, 200, %{"initialblockdownload" => true}} ->
            Logger.info("Bitcoin Core connected, waiting for initial block download");
            Process.send_after(self(), :check_status, 30 * 1000);
            {:noreply, {host, port, :ibd, creds, listeners, inflight}}

          _ ->
            Logger.info("Waiting to connect to Bitcoin Core");
            Process.send_after(self(), :check_status, 10 * 1000);
            {:noreply, {host, port, :disconnected, creds, listeners, inflight}}
        end

      {from, inflight} ->
        GenServer.reply(from, result)
        {:noreply, {host, port, status, creds, listeners, inflight}}
    end
  end

  @impl true
  def handle_call({:request, method, params}, from, {host, port, status, creds, listeners, inflight}) do
    case async_request(method, params, host, port, creds) do
      {:ok, task_ref} ->
        {:noreply, {host, port, status, creds, listeners, Map.put(inflight, task_ref, from)}}

      :error ->
        {:reply, 500, {host, port, status, creds, listeners, inflight}}
    end
  end

  @impl true
  def handle_call(:get_node_status, _from, {host, port, status, creds, listeners, inflight}) do
    {:reply, status, {host, port, status, creds, listeners, inflight}}
  end

  @impl true
  def handle_call(:notify_on_ready, from, {host, port, status, creds, listeners, inflight}) do
    {:noreply, {host, port, status, creds, [from | listeners], inflight}}
  end

  def notify_on_ready(pid) do
    GenServer.call(pid, :notify_on_ready, :infinity)
  end

  defp async_request(method, params, host, port, creds) do
    with  { user, pw } <- creds,
          {:ok, rpc_request} <- Jason.encode(%{method: method, params: params}) do
      task = Task.async(
        fn ->
          with  {:ok, %Finch.Response{body: body, headers: _headers, status: status}} <- Finch.build(:post, "http://#{host}:#{port}", [{"content-type", "application/json"}, {"authorization", BasicAuth.encode_basic_auth(user, pw)}], rpc_request) |> Finch.request(FinchClient),
                {:ok, %{"result" => info}} <- Jason.decode(body) do
            {:ok, status, info}
          else
            {:ok, status, _} ->
              Logger.error("RPC request #{method} failed with HTTP code #{status}")
              {:error, status}
            {:error, reason} ->
              Logger.error("RPC request #{method} failed");
              Logger.error("#{inspect(reason)}");
              {:error, reason}
            err ->
              Logger.error("RPC request #{method} failed: (unknown reason)");
              Logger.error("#{inspect(err)}");
              {:error, err}
          end
        end
      )
      {:ok, task.ref}
    else
      err ->
        Logger.error("failed to make RPC request");
        Logger.error("#{inspect(err)}");
        :error
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
              Logger.error("Failed to load bitcoin rpc cookie");
              Logger.error("#{inspect(reason)}")
              :error
            err ->
              Logger.error("Failed to load bitcoin rpc cookie: (unknown reason)");
              Logger.error("#{inspect(err)}")
              :error
          end
      true ->
        Logger.error("Missing bitcoin rpc credentials");
        :error
    end
  end
end
