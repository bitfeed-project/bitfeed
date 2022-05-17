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
    GenServer.start_link(__MODULE__, {host, port, nil, nil, [], %{}, nil}, opts)
  end

  @impl true
  def init({host, port, status, _, listeners, inflight, last_failure}) do
    # start node monitoring loop
    creds = rpc_creds();

    send(self(), :check_status);
    {:ok, {host, port, status, creds, listeners, inflight, last_failure}}
  end

  defp notify_listeners([]) do
    true
  end
  defp notify_listeners([head | tail]) do
    GenServer.reply(head, :mempool_synced);
    notify_listeners(tail)
  end

  # seconds until cool off period ends
  defp remaining_cool_off(now, time) do
    10 - Time.diff(now, time, :second)
  end

  defp is_cooling_off(time) do
    now = Time.utc_now;
    (remaining_cool_off(now, time) > 0)
  end

  @impl true
  def handle_info(:check_status, {host, port, status, creds, listeners, inflight, last_failure}) do
    case single_request("getblockchaininfo", [], host, port, creds) do
      {:ok, task_ref} ->
        {:noreply, {host, port, status, creds, listeners, Map.put(inflight, task_ref, :status), last_failure}}

      :error ->
        Logger.info("Waiting to connect to Bitcoin Core");
        Process.send_after(self(), :check_status, 10 * 1000);
        {:noreply, {host, port, status, creds, listeners, inflight, last_failure}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {host, port, status, creds, listeners, inflight, last_failure}) do
    {_, inflight} = Map.pop(inflight, ref);
    {:noreply, {host, port, status, creds, listeners, inflight, last_failure}}
  end

  @impl true
  def handle_info({ref, result}, {host, port, status, creds, listeners, inflight, last_failure}) do
    case Map.pop(inflight, ref) do
      {nil, inflight} ->
        {:noreply, {host, port, status, creds, listeners, inflight, last_failure}}

      {:status, inflight} ->
        case result do
          # if node is connected and finished with the initial block download
          {:ok, 200, %{"initialblockdownload" => false}} ->
            # notify all listening processes
            Logger.info("Bitcoin Core connected and synced");
            notify_listeners(listeners);
            Process.send_after(self(), :check_status, 300 * 1000);
            {:noreply, {host, port, :ok, creds, [], inflight, last_failure}}

          {:ok, 200, %{"initialblockdownload" => true}} ->
            Logger.info("Bitcoin Core connected, waiting for initial block download");
            Process.send_after(self(), :check_status, 30 * 1000);
            {:noreply, {host, port, :ibd, creds, listeners, inflight, last_failure}}

          _ ->
            Logger.info("Waiting to connect to Bitcoin Core");
            Process.send_after(self(), :check_status, 10 * 1000);
            {:noreply, {host, port, :disconnected, creds, listeners, inflight, last_failure}}
        end

      {from, inflight} ->
        GenServer.reply(from, result)
        {:noreply, {host, port, status, creds, listeners, inflight, last_failure}}
    end
  end

  @impl true
  def handle_call(:on_rpc_failure, _from, {host, port, status, creds, listeners, inflight, last_failure}) do
    if (last_failure != nil and is_cooling_off(last_failure)) do
      # don't reset if cooling period is already active
      {:reply, :ok, {host, port, status, creds, listeners, inflight, last_failure}}
    else
      Logger.info("RPC failure, cooling off non-essential requests for 10 seconds");
      {:reply, :ok, {host, port, status, creds, listeners, inflight, Time.utc_now}}
    end
  end

  @impl true
  def handle_call(:on_rpc_success, _from, {host, port, status, creds, listeners, inflight, last_failure}) do
    if (last_failure != nil) do
      if (is_cooling_off(last_failure)) do
        # don't clear an active cooling period
        {:reply, :ok, {host, port, status, creds, listeners, inflight, last_failure}}
      else
        Logger.info("RPC failure resolved, ending cool off period");
        {:reply, :ok, {host, port, status, creds, listeners, inflight, nil}}
      end
    else
      # cool off already cleared
      {:reply, :ok, {host, port, status, creds, listeners, inflight, nil}}
    end
  end

  @impl true
  def handle_call({:request, method, params}, from, {host, port, status, creds, listeners, inflight, last_failure}) do
    case single_request(method, params, host, port, creds) do
      {:ok, task_ref} ->
        {:noreply, {host, port, status, creds, listeners, Map.put(inflight, task_ref, from), last_failure}}

      :error ->
        {:reply, 500, {host, port, status, creds, listeners, inflight, last_failure}}
    end
  end

  @impl true
  def handle_call({:batch_request, method, batch_params, fail_fast}, from, {host, port, status, creds, listeners, inflight, last_failure}) do
    # enforce the 10 second cool-off period
    if (fail_fast and last_failure != nil and is_cooling_off(last_failure)) do
      # Logger.debug("skipping non-essential RPC request during cool-off period: #{remaining_cool_off(Time.utc_now, last_failure)} seconds remaining");
      {:reply, {:error, :cool_off}, {host, port, status, creds, listeners, inflight, last_failure}}
    else
      case do_batch_request(method, batch_params, host, port, creds) do
        {:ok, task_ref} ->
          {:noreply, {host, port, status, creds, listeners, Map.put(inflight, task_ref, from), last_failure}}

        :error ->
          {:reply, 500, {host, port, status, creds, listeners, inflight, last_failure}}
      end
    end
  end

  @impl true
  def handle_call(:get_node_status, _from, {host, port, status, creds, listeners, inflight, last_failure}) do
    {:reply, status, {host, port, status, creds, listeners, inflight, last_failure}}
  end

  @impl true
  def handle_call(:notify_on_ready, from, {host, port, status, creds, listeners, inflight, last_failure}) do
    {:noreply, {host, port, status, creds, [from | listeners], inflight, last_failure}}
  end

  def notify_on_ready(pid) do
    GenServer.call(pid, :notify_on_ready, :infinity)
  end

  defp single_request(method, params, host, port, creds) do
    case Jason.encode(%{method: method, params: params}) do
      {:ok, body} ->
        async_request(body, host, port, creds)

      err ->
        Logger.error("Failed to build RPC request body");
        {:error, err}
    end
  end

  defp do_batch_request(method, batch_params, host, port, creds) do
    case Jason.encode(Enum.map(batch_params, fn [params, id] -> %{method: method, params: params, id: id} end)) do
      {:ok, body} ->
        async_request(body, host, port, creds)

      err ->
        Logger.error("Failed to build RPC request body");
        {:error, err}
    end
  end

  defp submit_rpc(body, host, port, user, pw) do
    result = Finch.build(:post, "http://#{host}:#{port}", [{"content-type", "application/json"}, {"authorization", BasicAuth.encode_basic_auth(user, pw)}], body) |> Finch.request(FinchClient, [pool_timeout: 30000, receive_timeout: 30000]);
    case result do
      {:ok, %Finch.Response{body: response_body, headers: _headers, status: status}} ->
        { :ok, status, response_body }

      error ->
        Logger.debug("bad rpc response: #{inspect(error)}");
        { :error, error }
    end
  catch
    :exit, {:timeout, _} ->
      :timeout

    :exit, reason ->
      {:error, reason}

    error ->
      {:error, error}
  end

  defp async_request(body, host, port, creds) do
    with  { user, pw } <- creds do
      task = Task.async(
        fn ->
          with  {:ok, status, response_body} <- submit_rpc(body, host, port, user, pw),
                {:ok, response} <- Jason.decode(response_body) do
            case response do
              %{"result" => info} ->
                {:ok, status, info}

              _ -> {:ok, status, response}
            end
          else
            :timeout ->
              Logger.debug("rpc timeout");
              {:error, :timeout}

            {:ok, status, _} ->
              Logger.error("RPC request failed with HTTP code #{status}")
              {:error, status}
            {:error, reason} ->
              Logger.error("RPC request failed");
              Logger.error("#{inspect(reason)}");
              {:error, reason}
            err ->
              Logger.error("RPC request failed: (unknown reason)");
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
    GenServer.call(pid, {:request, method, params}, 60000)
  catch
    :exit, reason ->
      case reason do
        {:timeout, _} -> {:error, :timeout}

        _ -> {:error, reason}
      end

    error -> {:error, error}
  end

  # if fail_fast == true, an RPC failure triggers a cooling off period
  # where subsequent fail_fast=true requests immediately fail
  # RPC failures usually caused by resource saturation (exhausted local or remote RPC pool)
  # so this prevents RPC floods from causing cascading failures
  # calls with fail_fast=false are unaffected by the fail_fast cool-off period
  def batch_request(pid, method, batch_params, fail_fast \\ false) do
    case GenServer.call(pid, {:batch_request, method, batch_params, fail_fast}, 30000) do
      {:ok, status, result} ->
        if (fail_fast) do
          GenServer.call(pid, :on_rpc_success);
        end
        {:ok, status, result}

      {:error, :cool_off} ->
        {:error, :cool_off}

      {:error, error} ->
        if (fail_fast) do
          GenServer.call(pid, :on_rpc_failure);
        end
        {:error, error}

      catchall ->
        if (fail_fast) do
          GenServer.call(pid, :on_rpc_failure);
        end
        catchall
    end
  catch
    :exit, reason ->
      if (fail_fast) do
        GenServer.call(pid, :on_rpc_failure);
      end
      case reason do
        {:timeout, _} ->
          {:error, :timeout}

        _ -> {:error, reason}
      end

    error ->
      if (fail_fast) do
        GenServer.call(pid, :on_rpc_failure);
      end
      {:error, error}
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
