defmodule Rpi4Mouse.Rtmouse do
  use Supervisor

  require Logger

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

    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
