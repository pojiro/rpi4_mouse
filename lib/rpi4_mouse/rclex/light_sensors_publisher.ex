defmodule Rpi4Mouse.Rclex.LightSensorsPublisher do
  use GenServer

  require Logger

  alias Rclex.Pkgs.RaspimouseMsgs
  alias Rpi4Mouse.Rtmouse.LightSensors

  @default_interval_ms 100

  # API

  @doc """
  Set the publish interval in milliseconds.
  """
  @spec set_publish_interval(interval_ms :: pos_integer()) :: :ok | {:error, atom()}
  def set_publish_interval(interval_ms) when is_integer(interval_ms) and interval_ms > 0 do
    GenServer.cast(__MODULE__, {:set_interval, interval_ms})
  end

  def set_publish_interval(_interval_ms), do: {:error, :invalid_interval}

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    node_name = Keyword.fetch!(args, :node_name)
    interval_ms = Keyword.get(args, :interval_ms, @default_interval_ms)

    :ok = Rclex.start_publisher(RaspimouseMsgs.Msg.LightSensors, "/light_sensors", node_name)

    send(self(), :publish)

    {:ok, %{node_name: node_name, interval_ms: interval_ms}}
  end

  def handle_info(:publish, state) do
    values = LightSensors.get_values()
    msg = struct(RaspimouseMsgs.Msg.LightSensors, values)
    :ok = Rclex.publish(msg, "/light_sensors", state.node_name)

    Process.send_after(self(), :publish, state.interval_ms)

    {:noreply, state}
  end

  def handle_cast({:set_interval, interval_ms}, state) do
    Logger.info("#{__MODULE__}: publish interval set to #{interval_ms}ms")
    {:noreply, %{state | interval_ms: interval_ms}}
  end
end
