# Rpi4Mouse

<img src="https://github.com/pojiro/rpi4_mouse/assets/4096956/13398f9f-00b7-4595-80a9-1b10e8505604"
     style="width: 600px"
     alt="mouse_and_gamepad">

## Document for ME!

```
git clone git@github.com:pojiro/rpi4_mouse.git
export MIX_TARGET=rpi4_mouse
mix deps.get
export ROS_DISTRO=humble
mix rclex.prep.ros2 --arch arm64v8
# copy raspimouse_msg's include/lib/share directory to rootfs_overlay/opt/ros/humble
mix rclex.gen.msgs
mix firmware
mix upload
```

### control from host PC with Logicool F310 Gamepad

your linux user is needed to be `input` group user

```
# debian/ubuntu/mint
sudo adduser pojiro input
```

install https://github.com/rt-net/raspimouse_ros2_examples to HOST PC, then

```
ros2 launch raspimouse_ros2_examples teleop_joy.launch.py mouse:=true
```

### use [shiguredo/momo](https://github.com/shiguredo/momo) for camera

1. download momo-2022.4.1_raspberry-pi-os_armv8.tar.gz from https://github.com/shiguredo/momo/releases/tag/2022.4.1
2. untar it
3. then copy the directory, momo-2022.4.1_raspberry-pi-os_armv8, to `rootfs_overlay/opt/momo`.

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
