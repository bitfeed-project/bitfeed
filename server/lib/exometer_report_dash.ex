defmodule BitcoinStream.ExometerReportDash do
  @behaviour :exometer_report

  # Initializes the exometer_report with passed params
  # Requires :channel and :app_name options
  @impl true
  def exometer_init(opts) do
    IO.puts("Initialising dashboard exometer reporter")
    {:ok, opts}
  end

  # Converts the data passed by Exometer and relays it to the channel
  @impl true
  def exometer_report(metric, data_point, extra, value, opts) do
    id = name(metric, data_point)

    metric_payload = %{
      key: id,
      val: value,
      extra: extra,
      timestamp: :os.system_time(:milli_seconds)
    }

    Registry.dispatch(Registry.BitcoinStream, "metrics", fn(entries) ->
      for {pid, _} <- entries do
        # IO.puts("Forwarding to pid #{inspect pid}")
        case Jason.encode(%{type: "metric", metric: metric_payload}) do
          {:ok, payload} -> Process.send(pid, payload, []);
          {:error, reason} -> IO.puts("Error json encoding reporter metric: #{reason}");
        end
      end
    end)

    {:ok, opts}
  end

  @impl true
  def exometer_subscribe(_, _, _, _, opts), do: {:ok, opts}

  @impl true
  def exometer_unsubscribe(_, _, _, opts), do: {:ok, opts}

  @impl true
  def exometer_call(_, _, opts), do: {:ok, opts}

  @impl true
  def exometer_cast(_, opts), do: {:ok, opts}

  @impl true
  def exometer_info(_, opts), do: {:ok, opts}

  @impl true
  def exometer_newentry(_, opts), do: {:ok, opts}

  @impl true
  def exometer_setopts(_, _, _, opts), do: {:ok, opts}

  @impl true
  def exometer_terminate(_, _), do: nil

  defp name(metric, data_point) do
    Enum.join(metric, "_") <> "_" <> "#{data_point}"
  end
end
