defmodule Rpi4Mouse.Rtmouse.Leds do
  use GenServer

  require Logger

  @led_off 0
  @led_on 1

  # API

  @spec light(msg :: map()) :: :ok | {:error, atom()}
  def light(msg) do
    GenServer.call(__MODULE__, {:light, msg})
  end

  @spec get_states() :: map()
  def get_states() do
    GenServer.call(__MODULE__, :get_states)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    led0_dev = Keyword.fetch!(args, :led0_device)
    led1_dev = Keyword.fetch!(args, :led1_device)
    led2_dev = Keyword.fetch!(args, :led2_device)
    led3_dev = Keyword.fetch!(args, :led3_device)

    led0 = open_device(led0_dev)
    led1 = open_device(led1_dev)
    led2 = open_device(led2_dev)
    led3 = open_device(led3_dev)

    # 初期状態: すべてのLEDオフ
    IO.write(led0, "0")
    IO.write(led1, "0")
    IO.write(led2, "0")
    IO.write(led3, "0")

    {:ok,
     %{
       led0: led0,
       led1: led1,
       led2: led2,
       led3: led3,
       led0_state: @led_off,
       led1_state: @led_off,
       led2_state: @led_off,
       led3_state: @led_off
     }}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    # 終了時は必ずすべてのLEDを消灯
    IO.write(state.led0, "0")
    IO.write(state.led1, "0")
    IO.write(state.led2, "0")
    IO.write(state.led3, "0")

    File.close(state.led0)
    File.close(state.led1)
    File.close(state.led2)
    File.close(state.led3)
  end

  def handle_call({:light, msg}, _from, state) do
    # LED値変換と書き込み
    with {:ok, led0_val} <- to_led_value(msg.led0),
         {:ok, led1_val} <- to_led_value(msg.led1),
         {:ok, led2_val} <- to_led_value(msg.led2),
         {:ok, led3_val} <- to_led_value(msg.led3) do
      # LED書き込み
      IO.write(state.led0, "#{led0_val}")
      IO.write(state.led1, "#{led1_val}")
      IO.write(state.led2, "#{led2_val}")
      IO.write(state.led3, "#{led3_val}")

      new_state = %{
        state
        | led0_state: led0_val,
          led1_state: led1_val,
          led2_state: led2_val,
          led3_state: led3_val
      }

      {:reply, :ok, new_state}
    else
      {:error, reason} ->
        Logger.error("#{__MODULE__}: invalid LED value - #{reason}")
        {:reply, {:error, :invalid_led_value}, state}
    end
  end

  def handle_call(:get_states, _from, state) do
    {:reply,
     %{
       led0: state.led0_state,
       led1: state.led1_state,
       led2: state.led2_state,
       led3: state.led3_state
     }, state}
  end

  # Private

  defp open_device(path) do
    if File.exists?(path) do
      File.open!(path, [:write])
    else
      Logger.warning("#{__MODULE__}: device #{path} not found, using /dev/null")
      File.open!("/dev/null", [:write])
    end
  end

  defp to_led_value(true), do: {:ok, @led_on}
  defp to_led_value(false), do: {:ok, @led_off}
  defp to_led_value(val), do: {:error, "value must be boolean, got: #{inspect(val)}"}
end
