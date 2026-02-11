defmodule Rpi4Mouse.Rclex do
  use Supervisor

  require Logger

  alias Rpi4Mouse.Rclex.CmdVelSubscriber
  alias Rpi4Mouse.Rclex.BuzzerSubscriber
  alias Rpi4Mouse.Rclex.LedsSubscriber
  alias Rpi4Mouse.Rclex.LightSensorsPublisher
  alias Rpi4Mouse.Rclex.SwitchesPublisher

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    node_name = Keyword.get(args, :node_name, "rpi4_mouse")
    ifname = Keyword.get(args, :ifname, "eth0")
    light_interval_ms = Keyword.get(args, :light_sensors_publish_interval_ms, 100)
    switch_interval_ms = Keyword.get(args, :switches_publish_interval_ms, 100)

    wait_for_interface(ifname)

    :ok = Rclex.start_node(node_name)
    Logger.info("#{__MODULE__}: ROS2 node started with name: #{node_name}")

    children = [
      {CmdVelSubscriber, [node_name: node_name]},
      {BuzzerSubscriber, [node_name: node_name]},
      {LedsSubscriber, [node_name: node_name]},
      {LightSensorsPublisher, [node_name: node_name, interval_ms: light_interval_ms]},
      {SwitchesPublisher, [node_name: node_name, interval_ms: switch_interval_ms]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  if Mix.target() == :host do
    defp wait_for_interface(_ifname), do: :ok
  else
    defp wait_for_interface(ifname) do
      case VintageNet.get(["interface", ifname, "connection"]) do
        status when status in [:lan, :internet] ->
          Logger.info("#{__MODULE__}: interface #{ifname} is up with status: #{status}")
          :ok

        _ ->
          Logger.debug("#{__MODULE__}: waiting for interface #{ifname}...")
          Process.sleep(1000)
          wait_for_interface(ifname)
      end
    end
  end
end
