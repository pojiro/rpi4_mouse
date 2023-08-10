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

    {:noreply, state}
  end
end
