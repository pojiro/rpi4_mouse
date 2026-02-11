defmodule Rpi4Mouse.Rclex.BuzzerSubscriber do
  use GenServer

  require Logger

  alias Rclex.Pkgs.StdMsgs

  # API

  def set_debug(debug) when is_boolean(debug) do
    GenServer.cast(__MODULE__, {:set_debug, debug})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    node_name = Keyword.fetch!(args, :node_name)
    debug = Keyword.get(args, :debug, false)
    pid = self()

    :ok =
      Rclex.start_subscription(
        fn msg -> send(pid, {:buzzer, msg}) end,
        StdMsgs.Msg.Int16,
        "/buzzer",
        node_name
      )

    Logger.info("#{__MODULE__}: subscribed to /buzzer")

    {:ok, %{debug: debug}}
  end

  def terminate(_reason, _state) do
    Logger.info("#{__MODULE__}: terminating")
  end

  def handle_info({:buzzer, msg}, state) do
    if state.debug do
      Logger.debug("#{__MODULE__}: received /buzzer: #{inspect(msg)}")
    end

    Rpi4Mouse.Rtmouse.Buzzer.beep(msg)

    {:noreply, state}
  end

  def handle_cast({:set_debug, debug}, state) do
    Logger.info("#{__MODULE__}: debug #{if debug, do: "enabled", else: "disabled"}")
    {:noreply, %{state | debug: debug}}
  end
end
