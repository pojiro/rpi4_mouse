defmodule Rpi4Mouse.Rclex.CmdVelSubscriber do
  use GenServer

  require Logger

  alias Rclex.Pkgs.GeometryMsgs

  # API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    node_name = Keyword.fetch!(args, :node_name)

    :ok =
      Rclex.start_subscription(
        fn msg -> send(self(), {:cmd_vel, msg}) end,
        GeometryMsgs.Msg.TwistStamped,
        "/cmd_vel",
        node_name
      )

    Logger.info("#{__MODULE__}: subscribed to /cmd_vel")

    {:ok, %{}}
  end

  def terminate(_reason, _state) do
    Logger.info("#{__MODULE__}: terminating")
  end

  def handle_info({:cmd_vel, msg}, state) do
    Logger.debug("#{__MODULE__}: received /cmd_vel: #{inspect(msg)}")

    # TODO: モーター制御を呼び出す
    # Task.start_link(fn -> Rpi4Mouse.Rtmouse.Motor.drive(:left, msg) end)
    # Task.start_link(fn -> Rpi4Mouse.Rtmouse.Motor.drive(:right, msg) end)

    {:noreply, state}
  end
end
