defmodule Rpi4Mouse.Rclex.LedsSubscriber do
  use GenServer

  require Logger

  alias Rclex.Pkgs.RaspimouseMsgs

  # API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    node_name = Keyword.fetch!(args, :node_name)
    pid = self()

    :ok =
      Rclex.start_subscription(
        fn msg -> send(pid, {:leds, msg}) end,
        RaspimouseMsgs.Msg.Leds,
        "/leds",
        node_name
      )

    Logger.info("#{__MODULE__}: subscribed to /leds")

    {:ok, %{}}
  end

  def terminate(_reason, _state) do
    Logger.info("#{__MODULE__}: terminating")
  end

  def handle_info({:leds, msg}, state) do
    Logger.debug("#{__MODULE__}: received /leds: #{inspect(msg)}")

    # TODO: LED制御を呼び出す
    # Task.start_link(fn -> Rpi4Mouse.Rtmouse.Led.drive(:led0, msg) end)
    # Task.start_link(fn -> Rpi4Mouse.Rtmouse.Led.drive(:led1, msg) end)
    # Task.start_link(fn -> Rpi4Mouse.Rtmouse.Led.drive(:led2, msg) end)
    # Task.start_link(fn -> Rpi4Mouse.Rtmouse.Led.drive(:led3, msg) end)

    {:noreply, state}
  end
end
