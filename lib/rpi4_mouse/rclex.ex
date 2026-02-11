defmodule Rpi4Mouse.Rclex do
  use Supervisor

  require Logger

  alias Rpi4Mouse.Rclex.CmdVelSubscriber
  alias Rpi4Mouse.Rclex.BuzzerSubscriber

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    node_name = Keyword.get(args, :node_name, "rpi4_mouse")
    ifname = Keyword.get(args, :ifname, "eth0")

    wait_for_interface(ifname)

    :ok = Rclex.start_node(node_name)
    Logger.info("#{__MODULE__}: ROS2 node started with name: #{node_name}")

    children = [
      {CmdVelSubscriber, [node_name: node_name]},
      {BuzzerSubscriber, [node_name: node_name]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

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
