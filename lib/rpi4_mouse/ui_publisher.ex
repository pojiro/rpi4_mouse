defmodule Rpi4Mouse.UiPublisher do
  @moduledoc """
  Publishes RT Mouse device states to Phoenix UI via PubSub.

  Broadcasts sensor and actuator states to the web UI at a configurable interval.
  """
  use GenServer

  require Logger

  alias Rpi4Mouse.Rtmouse.{Motors, Buzzer, Leds, LightSensors, Switches}

  @default_interval_ms 100
  @topic "Rpi4Mouse"

  # API

  @doc """
  Start publishing UI data at the configured interval.
  """
  @spec start_publish() :: :ok
  def start_publish() do
    GenServer.cast(__MODULE__, :start_publish)
  end

  @doc """
  Stop publishing UI data.
  """
  @spec stop_publish() :: :ok
  def stop_publish() do
    GenServer.cast(__MODULE__, :stop_publish)
  end

  @doc """
  Set the publishing interval in milliseconds.
  """
  @spec set_publish_interval(pos_integer()) :: :ok
  def set_publish_interval(interval_ms) when is_integer(interval_ms) and interval_ms > 0 do
    GenServer.call(__MODULE__, {:set_interval, interval_ms})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    interval_ms = Keyword.get(args, :publish_interval_ms, @default_interval_ms)

    state = %{
      interval_ms: interval_ms,
      enabled?: true,
      timer_ref: nil
    }

    # Start publishing after a brief delay to ensure all devices are ready
    Process.send_after(self(), :publish, 1000)

    {:ok, state}
  end

  def handle_call({:set_interval, interval_ms}, _from, state) do
    # Cancel existing timer if any
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

    # Schedule next publish with new interval
    timer_ref =
      if state.enabled? do
        Process.send_after(self(), :publish, interval_ms)
      else
        nil
      end

    {:reply, :ok, %{state | interval_ms: interval_ms, timer_ref: timer_ref}}
  end

  def handle_cast(:start_publish, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

    timer_ref = Process.send_after(self(), :publish, 0)
    {:noreply, %{state | enabled?: true, timer_ref: timer_ref}}
  end

  def handle_cast(:stop_publish, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

    {:noreply, %{state | enabled?: false, timer_ref: nil}}
  end

  def handle_info(:publish, state) do
    if state.enabled? do
      msg = collect_device_states()

      Phoenix.PubSub.broadcast(Rpi4MouseUi.PubSub, @topic, msg)

      timer_ref = Process.send_after(self(), :publish, state.interval_ms)
      {:noreply, %{state | timer_ref: timer_ref}}
    else
      {:noreply, %{state | timer_ref: nil}}
    end
  end

  # Private Functions

  defp collect_device_states() do
    motor_state = Motors.get_state()
    light_sensors = LightSensors.get_values()
    leds = Leds.get_lights()

    %{
      is_motor_enable?: motor_state[:enabled?],
      left_motor_state: %{
        coeff: -1,
        pwm_hz: motor_state[:left_pwm],
        velocity: motor_state[:left_velocity]
      },
      right_motor_state: %{
        coeff: 1,
        pwm_hz: motor_state[:right_pwm],
        velocity: motor_state[:right_velocity]
      },
      light_sensors_values: %{
        fl: light_sensors[:forward_l],
        fr: light_sensors[:forward_r],
        l: light_sensors[:left],
        r: light_sensors[:right]
      },
      switches_values: Switches.get_values(),
      leds_values: %{
        led0: leds[:led0] == 1,
        led1: leds[:led1] == 1,
        led2: leds[:led2] == 1,
        led3: leds[:led3] == 1
      },
      buzzer_tone: Buzzer.get_tone()
    }
  end
end
