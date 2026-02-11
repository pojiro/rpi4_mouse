defmodule Rpi4Mouse.Rtmouse.LightSensors do
  use GenServer

  require Logger

  @type light_values :: %{
          forward_r: non_neg_integer(),
          right: non_neg_integer(),
          left: non_neg_integer(),
          forward_l: non_neg_integer()
        }

  # API

  @doc """
  Read and return light sensor values.
  """
  @spec get_values() :: light_values()
  def get_values() do
    GenServer.call(__MODULE__, :get_values)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    device_path = resolve_device_path(Keyword.fetch!(args, :light_sensor_device))

    {:ok, %{device_path: device_path, values: empty_values()}}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")
  end

  def handle_call(:get_values, _from, state) do
    values = read_values(state.device_path)
    {:reply, values, %{state | values: values}}
  end

  # Private

  defp resolve_device_path(path) do
    if File.exists?(path) do
      path
    else
      Logger.warning("#{__MODULE__}: device #{path} not found, using /dev/null")
      "/dev/null"
    end
  end

  defp read_values(path) do
    values =
      case File.read(path) do
        {:ok, binary} ->
          parse_values(binary)

        {:error, _} ->
          [0, 0, 0, 0]
      end

    [forward_r, right, left, forward_l] = values

    %{
      forward_r: forward_r,
      right: right,
      left: left,
      forward_l: forward_l
    }
  end

  defp parse_values(binary) do
    case String.trim(binary) do
      "" ->
        [0, 0, 0, 0]

      trimmed ->
        parts = String.split(trimmed, " ", trim: true)

        case Enum.map(parts, &Integer.parse/1) do
          [{forward_r, ""}, {right, ""}, {left, ""}, {forward_l, ""}] ->
            [forward_r, right, left, forward_l]

          _ ->
            [0, 0, 0, 0]
        end
    end
  end

  defp empty_values() do
    %{forward_r: 0, right: 0, left: 0, forward_l: 0}
  end
end
