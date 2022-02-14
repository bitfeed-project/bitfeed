Application.ensure_all_started(:hackney)

defmodule BitcoinStream.RPC do
  @moduledoc """
  GenServer for bitcoin rpc requests
  """
  use GenServer

  def start_link(opts) do
    {port, opts} = Keyword.pop(opts, :port);
    {host, opts} = Keyword.pop(opts, :host);
    IO.puts("Starting Bitcoin RPC server on #{host} port #{port}")
    GenServer.start_link(__MODULE__, {host, port, nil}, opts)
  end

  @impl true
  def init(state) do
    # start node monitoring loop
    send(self(), :check_status)
    {:ok, state}
  end

  def handle_info(:check_status, state) do
      # Do the desired work here
      state = check_status(state)
      Process.send_after(self(), :check_status, 60 * 1000)
      {:noreply, state}
  end

  @impl true
  def handle_call({:request, method, params}, _from, {host, port, status}) do
    case make_request(host, port, method, params) do
      {:ok, code, info} ->
        {:reply, {:ok, code, info}, {host, port, status}}

      {:error, reason} ->
        {:reply, {:error, reason}, {host, port, status}}
    end
  end

  @impl true
  def handle_call({:get_node_status}, _from, {host, port, status}) do
    {:reply, {:ok, status}, {host, port, status}}
  end

  defp make_request(host, port, method, params) do
    with  { user, pw } <- rpc_creds(),
          {:ok, rpc_request} <- Jason.encode(%{method: method, params: params}),
          {:ok, code, _headers, body_ref} <- :hackney.request(:post, "http://#{host}:#{port}", [{"content-type", "application/json"}], rpc_request, [basic_auth: { user, pw }]),
          {:ok, body} <- :hackney.body(body_ref),
          {:ok, %{"result" => info}} <- Jason.decode(body) do
      {:ok, code, info}
    else
      {:ok, code, _} ->
        IO.puts("RPC request #{method} failed with HTTP code #{code}")
        {:error, code}
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
    GenServer.call(pid, {:request, method, params}, 60000)
  catch
    :exit, reason ->
      IO.puts("RPC request #{method} failed - probably timed out?")
      IO.inspect(reason)
  end

  def get_node_status(pid) do
    GenServer.call(pid, {:get_node_status})
  end

  def check_status({host, port, status}) do
    with  {:ok, 200, info} <- make_request(host, port, "getblockchaininfo", []) do
      {host, port, info}
    else
      {:error, reason} ->
        IO.puts("node status check failed");
        IO.inspect(reason)
        {host, port, status}
      err ->
        IO.puts("node status check failed: (unknown reason)");
        IO.inspect(err);
        {host, port, status}
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
