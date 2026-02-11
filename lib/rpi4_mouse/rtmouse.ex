defmodule Rpi4Mouse.Rtmouse do
  use Supervisor

  require Logger

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    cond do
      is_nil(System.find_executable("modprobe")) ->
        Logger.error("modprobe not found")

      {_, 0} = System.cmd("modprobe", ~w"rtmouse.ko") ->
        Logger.info("rtmouse.ko loaded")

      true ->
        Logger.error("Failed to load rtmouse.ko")
    end

    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
