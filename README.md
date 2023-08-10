# Rpi4Mouse

## Document for ME!

```
git clone git@github.com:pojiro/rpi4_mouse.git
export MIX_TARGET=rpi4_mouse
mix deps.get
export ROS_DISTRO=foxy
mix rclex.prep.ros2 --arch arm64v8
# copy raspimouse_msg's include/lib/share directory to rootfs_overlay/opt/ros/foxy
mix rclex.gen.msgs
mix firmware
mix upload
```
### control from host PC with Logicool F310 Gamepad

install https://github.com/rt-net/raspimouse_ros2_examples to HOST PC, then

```
ros2 launch raspimouse_ros2_examples teleop_joy.launch.py mouse:=true
```

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
