defmodule Rpi4Mouse do
  @moduledoc """
  Documentation for Rpi4Mouse.
  """
  use GenServer

  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    with bin <- System.find_executable("modprobe"),
         {_, 0} <- System.cmd(bin, ~w"rtmouse.ko") do
      send(self(), :start)
    end

    {:ok, %{}}
  end

  def handle_info(:start, state) do
    # NOTE
    # Nerves の Network 類の起動を待たないうちに起動してすると
    # サブスクライバがなぜか動作しない（原因不明）ため決め打ちで待つ
    Process.sleep(5_000)

    Application.ensure_all_started(:raspimouse2_ex)
    |> tap(&Logger.info("#{__MODULE__}: ensure_all_started return is #{inspect(&1)}"))

    send(self(), :publish)

    {:noreply, state}
  end

  def handle_info(:publish, state) do
    msg = %{
      buzzer_tone: Raspimouse2Ex.get_buzzer_tone(),
      is_motor_enable?: Raspimouse2Ex.is_motor_enable?(),
      leds_values: Raspimouse2Ex.get_leds_values(),
      left_motor_state: Raspimouse2Ex.get_left_motor_state(),
      light_sensors_values: Raspimouse2Ex.get_light_sensors_values(),
      right_motor_state: Raspimouse2Ex.get_right_motor_state(),
      switches_values: Raspimouse2Ex.get_switches_values()
    }

    Phoenix.PubSub.broadcast(Rpi4MouseUi.PubSub, "Rpi4Mouse", msg)

    Process.send_after(self(), :publish, 100)

    {:noreply, state}
  end
end
