defmodule BitcoinStream.Metrics.Probe do
  use GenServer
  use Elixometer

  def child_spec() do
    %{
      id: BitcoinStream.Metrics.Probe,
      start: {BitcoinStream.Metrics.Probe, :start_link, []}
    }
  end

  def start_link(_) do
    IO.puts("Starting custom metrics probe");
    GenServer.start_link(__MODULE__, %{})
  end

  def init(arg) do
    IO.puts("Initialising custom metrics probe");
    :timer.send_interval(1000, :tick);
    {:ok, arg}
  end

  def handle_info(:tick, state) do
    connections = Registry.count(Registry.BitcoinStream);
    update_gauge("sockets", connections);
    {:noreply, state}
  end
end
