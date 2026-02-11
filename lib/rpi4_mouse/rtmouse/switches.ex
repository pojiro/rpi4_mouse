defmodule Rpi4Mouse.Rtmouse.Switches do
  use GenServer

  require Logger

  @type switch_values :: %{
          switch0: boolean(),
          switch1: boolean(),
          switch2: boolean()
        }

  # API

  @doc """
  Read and return switch states.
  """
  @spec get_values() :: switch_values()
  def get_values() do
    GenServer.call(__MODULE__, :get_values)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    device_paths = %{
      switch0: resolve_device_path(Keyword.fetch!(args, :switch0_device)),
      switch1: resolve_device_path(Keyword.fetch!(args, :switch1_device)),
      switch2: resolve_device_path(Keyword.fetch!(args, :switch2_device))
    }

    {:ok, %{device_paths: device_paths, values: empty_values()}}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")
  end

  def handle_call(:get_values, _from, state) do
    values = read_values(state.device_paths)
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

  defp read_values(device_paths) do
    %{
      switch0: read_switch(device_paths.switch0),
      switch1: read_switch(device_paths.switch1),
      switch2: read_switch(device_paths.switch2)
    }
  end

  defp read_switch(path) do
    case File.read(path) do
      {:ok, "0\n"} -> true
      {:ok, "1\n"} -> false
      {:ok, _} -> false
      {:error, _} -> false
    end
  end

  defp empty_values() do
    %{switch0: false, switch1: false, switch2: false}
  end
end
