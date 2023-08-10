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
    if bin = System.find_executable("modprobe") do
      {_, 0} = System.cmd(bin, ~w"rtmouse.ko")
    end

    # Application.ensure_all_started(:raspimouse2_ex)
    # |> tap(&Logger.info("#{__MODULE__}: ensure_all_started return is #{inspect(&1)}"))

    {:ok, %{}}
  end
end
