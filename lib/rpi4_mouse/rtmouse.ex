defmodule Rpi4Mouse.Rtmouse do
  use Supervisor

  require Logger

  alias Rpi4Mouse.Rtmouse.Motors
  alias Rpi4Mouse.Rtmouse.Buzzer
  alias Rpi4Mouse.Rtmouse.Leds
  alias Rpi4Mouse.Rtmouse.LightSensors
  alias Rpi4Mouse.Rtmouse.Switches
  alias Rpi4Mouse.UiPublisher

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    case System.find_executable("modprobe") do
      nil ->
        Logger.error("modprobe not found")

      modprobe_path ->
        case System.cmd(modprobe_path, ~w"rtmouse.ko") do
          {_, 0} ->
            Logger.info("rtmouse.ko loaded")

          _ ->
            Logger.error("Failed to load rtmouse.ko")
        end
    end

    children = [
      {Motors,
       [
         left_device: "/dev/rtmotor_raw_l0",
         right_device: "/dev/rtmotor_raw_r0",
         enable_device: "/dev/rtmotoren0"
       ]},
      {Buzzer, [buzzer_device: "/dev/rtbuzzer0"]},
      {Leds,
       [
         led0_device: "/dev/rtled0",
         led1_device: "/dev/rtled1",
         led2_device: "/dev/rtled2",
         led3_device: "/dev/rtled3"
       ]},
      {LightSensors, [light_sensor_device: "/dev/rtlightsensor0"]},
      {Switches,
       [
         switch0_device: "/dev/rtswitch0",
         switch1_device: "/dev/rtswitch1",
         switch2_device: "/dev/rtswitch2"
       ]},
      {UiPublisher, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
