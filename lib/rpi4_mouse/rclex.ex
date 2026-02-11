defmodule Rpi4Mouse.Rclex do
  use Supervisor

  require Logger

  alias Rpi4Mouse.Rclex.CmdVelSubscriber

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    node_name = Keyword.get(args, :node_name, "rpi4_mouse")

    :ok = Rclex.start_node(node_name)
    Logger.info("#{__MODULE__}: ROS2 node started with name: #{node_name}")

    children = [
      {CmdVelSubscriber, [node_name: node_name]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
