defmodule Rpi4Mouse.Rclex.CmdVelSubscriber do
  use GenServer

  require Logger

  alias Rclex.Pkgs.GeometryMsgs

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
      fn msg -> send(pid, {:cmd_vel, msg}) end
      |> Rclex.start_subscription(GeometryMsgs.Msg.TwistStamped, "/cmd_vel", node_name)

    Logger.info("#{__MODULE__}: subscribed to /cmd_vel")

    {:ok, %{debug: debug}}
  end

  def terminate(_reason, _state) do
    Logger.info("#{__MODULE__}: terminating")
  end

  def handle_info({:cmd_vel, msg}, state) do
    if state.debug do
      Logger.debug("#{__MODULE__}: received /cmd_vel: #{inspect(msg)}")
    end

    %{twist: %{linear: %{x: x}, angular: %{z: z}}} = msg
    Rpi4Mouse.Rtmouse.Motors.drive(x, z)

    {:noreply, state}
  end

  def handle_cast({:set_debug, debug}, state) do
    Logger.info("#{__MODULE__}: debug #{if debug, do: "enabled", else: "disabled"}")
    {:noreply, %{state | debug: debug}}
  end
end
