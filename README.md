# Rpi4Mouse

[Raspberry Pi Mouse](https://rt-net.jp/products/raspberrypimousev3/) integrated with [Nerves](https://nerves-project.org/) and [rclex](https://github.com/rclex/rclex) for ROS2 support.

<img src="https://github.com/pojiro/rpi4_mouse/assets/4096956/13398f9f-00b7-4595-80a9-1b10e8505604"
     width="600"
     alt="mouse_and_gamepad">

## Features

- **Direct device driver control**: Interfaces directly with RT Mouse kernel modules
- **ROS2 integration**: Subscribes to `/cmd_vel`, `/buzzer`, `/leds` and publishes `/light_sensors`, `/switches`
- **Phoenix LiveView UI**: Real-time web UI for monitoring sensor data and motor states
- **Modular architecture**: Clean separation between device layer, ROS2 layer, and UI layer

## Architecture

### Device Layer (`Rpi4Mouse.Rtmouse.*`)

Direct control of RT Mouse hardware via device files created by the `rtmouse.ko` kernel module:

- **Motors** (`/dev/rtmotor_raw_l0`, `/dev/rtmotor_raw_r0`, `/dev/rtmotoren0`): Differential drive control with velocity/PWM conversion
- **Buzzer** (`/dev/rtbuzzer0`): Frequency control (0-20000 Hz)
- **LEDs** (`/dev/rtled0-3`): Individual LED control
- **LightSensors** (`/dev/rtlightsensor0`): 4-channel light sensor readings
- **Switches** (`/dev/rtswitch0-2`): 3 push button states

### ROS2 Layer (`Rpi4Mouse.Rclex.*`)

ROS2 subscribers and publishers via [rclex](https://github.com/rclex/rclex):

**Subscribers:**
- `/cmd_vel` (geometry_msgs/TwistStamped) → Motors
- `/buzzer` (std_msgs/Int16) → Buzzer
- `/leds` (raspimouse_msgs/Leds) → LEDs

**Publishers:**
- `/light_sensors` (raspimouse_msgs/LightSensors)
- `/switches` (raspimouse_msgs/Switches)

### UI Layer

- **UiPublisher**: Broadcasts device states to Phoenix LiveView UI at 100ms intervals
- **Web UI**: Real-time monitoring via Phoenix LiveView (from `rpi4_mouse_ui` dependency)

## Quick Start

### Build and Deploy

```bash
git clone git@github.com:pojiro/rpi4_mouse.git
cd rpi4_mouse
export MIX_TARGET=rpi4_mouse

# Get dependencies
mix deps.get
mix deps.compile

# Prepare ROS2 (for arm64v8 target)
export ROS_DISTRO=jazzy
mix rclex.prep.ros2 --arch arm64v8

# Copy raspimouse_msgs include/lib/share to rootfs_overlay/opt/ros/jazzy
# Generate ROS2 message bindings
mix rclex.gen.msgs

# Build and upload firmware
mix prod.firmware
mix prod.upload
```

### Control from Host PC

#### With Logicool F310 Gamepad

Add your user to the `input` group (requires reboot):

```bash
# Debian/Ubuntu/Mint
sudo adduser $USER input
```

Install [raspimouse_ros2_examples](https://github.com/rt-net/raspimouse_ros2_examples) on your host PC:

```bash
ros2 launch raspimouse_ros2_examples teleop_joy.launch.py mouse:=true
```

#### Web UI

Access the Phoenix LiveView UI at `http://nerves.local` (or your device's IP address).

## API Reference

### Device Control APIs

```elixir
# Motors - Drive with linear/angular velocity
Rpi4Mouse.Rtmouse.Motors.drive(linear_x, angular_z)
Rpi4Mouse.Rtmouse.Motors.get_state()

# Buzzer - Set frequency (0-20000 Hz)
Rpi4Mouse.Rtmouse.Buzzer.beep(hz)
Rpi4Mouse.Rtmouse.Buzzer.get_tone()

# LEDs - Control individual LEDs
Rpi4Mouse.Rtmouse.Leds.light(%{led0: true, led1: false, led2: true, led3: false})
Rpi4Mouse.Rtmouse.Leds.get_lights()

# Sensors - Read current values
Rpi4Mouse.Rtmouse.LightSensors.get_values()  # => %{forward_r:, right:, left:, forward_l:}
Rpi4Mouse.Rtmouse.Switches.get_values()      # => %{switch0:, switch1:, switch2:}
```

### ROS2 Publisher Control

```elixir
# Control sensor publishing
Rpi4Mouse.Rclex.LightSensorsPublisher.stop_publish()
Rpi4Mouse.Rclex.LightSensorsPublisher.start_publish()
Rpi4Mouse.Rclex.LightSensorsPublisher.set_publish_interval(200)  # ms

Rpi4Mouse.Rclex.SwitchesPublisher.stop_publish()
Rpi4Mouse.Rclex.SwitchesPublisher.start_publish()
Rpi4Mouse.Rclex.SwitchesPublisher.set_publish_interval(200)  # ms
```

### UI Publishing Control

```elixir
# Control web UI updates
Rpi4Mouse.UiPublisher.stop_publish()
Rpi4Mouse.UiPublisher.start_publish()
Rpi4Mouse.UiPublisher.set_publish_interval(100)  # ms
```

## Configuration

### Optional: Camera Streaming with Momo

To enable camera streaming with [shiguredo/momo](https://github.com/shiguredo/momo):

1. Download `momo-2025.1.0_raspberry-pi-os_armv8.tar.gz` from [releases](https://github.com/shiguredo/momo/releases/tag/2025.1.0)
2. Extract and copy the entire directory to `rootfs_overlay/opt/momo/`
3. Rebuild firmware

## Development

### Type Checking

The project uses [Dialyxir](https://github.com/jeremyjh/dialyxir) for static type analysis:

```bash
mix dialyzer
```

### Code Formatting

```bash
mix format
```

### Development Firmware

For faster iteration during development:

```bash
# Build and upload development firmware (includes extra tools)
mix dev.firmware && mix dev.upload
```

### IEx Access

Connect to the running device via SSH:

```bash
ssh nerves.local
```

## Targets

This Nerves application targets `rpi4_mouse`, a custom Nerves system based on Raspberry Pi 4 with RT Mouse kernel modules.

- **Host target** (`MIX_TARGET` unset): For running tests and utilities on your development machine
- **rpi4_mouse target** (`MIX_TARGET=rpi4_mouse`): For deploying to Raspberry Pi Mouse hardware

For more information about Nerves targets:
https://hexdocs.pm/nerves/targets.html

## Dependencies

- **Elixir**: 1.18+
- **Erlang/OTP**: 28+
- **Nerves**: 1.10+
- **rclex**: ROS2 Jazzy integration
- **Phoenix LiveView**: Web UI framework

## Learn more

* Official Nerves docs: https://hexdocs.pm/nerves/getting-started.html
* Nerves Project: https://nerves-project.org/
* Raspberry Pi Mouse: https://rt-net.jp/products/raspberrypimousev3/
* rclex: https://github.com/rclex/rclex
