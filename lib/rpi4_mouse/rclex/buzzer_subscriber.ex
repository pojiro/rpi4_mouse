defmodule Rpi4Mouse.Rclex.BuzzerSubscriber do
  use GenServer

  require Logger

  alias Rclex.Pkgs.StdMsgs

  # API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    node_name = Keyword.fetch!(args, :node_name)

    :ok =
      Rclex.start_subscription(
        fn msg -> send(self(), {:buzzer, msg}) end,
        StdMsgs.Msg.Int16,
        "/buzzer",
        node_name
      )

    Logger.info("#{__MODULE__}: subscribed to /buzzer")

    {:ok, %{}}
  end

  def terminate(_reason, _state) do
    Logger.info("#{__MODULE__}: terminating")
  end

  def handle_info({:buzzer, msg}, state) do
    Logger.debug("#{__MODULE__}: received /buzzer: #{inspect(msg)}")

    # TODO: ブザー制御を呼び出す
    # Rpi4Mouse.Rtmouse.Buzzer.beep(msg)

    {:noreply, state}
  end
end
