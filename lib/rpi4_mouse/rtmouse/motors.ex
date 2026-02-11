defmodule Rpi4Mouse.Rtmouse.Motors do
  use GenServer

  require Logger

  @wheel_dia_meter 0.048
  @wheel_tread_meter 0.0925
  @timeout_ms 10_000

  # API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec drive(msg :: map()) :: :ok
  def drive(%{twist: %{linear: %{x: x}, angular: %{z: z}}} = _msg) do
    GenServer.call(__MODULE__, {:drive, {x, z}})
  end

  @spec get_state() :: map()
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  # Callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    left_dev = Keyword.fetch!(args, :left_device)
    right_dev = Keyword.fetch!(args, :right_device)
    enable_dev = Keyword.fetch!(args, :enable_device)

    left_file = open_device(left_dev)
    right_file = open_device(right_dev)
    enable_file = open_device(enable_dev)

    # 初期状態: モーター無効、PWM = 0
    IO.write(left_file, "0")
    IO.write(right_file, "0")
    IO.write(enable_file, "0")

    {:ok,
     %{
       left: left_file,
       right: right_file,
       enable: enable_file,
       enabled?: false,
       left_pwm: 0,
       right_pwm: 0
     }}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    # 終了時は必ず停止
    IO.write(state.left, "0")
    IO.write(state.right, "0")
    IO.write(state.enable, "0")

    File.close(state.left)
    File.close(state.right)
    File.close(state.enable)
  end

  def handle_call({:drive, {x, z}}, _from, state) do
    # 左右のモーター速度を計算
    left_velocity = x - z * @wheel_tread_meter / 2
    right_velocity = x + z * @wheel_tread_meter / 2

    left_pwm = velocity_to_pwm(left_velocity)
    right_pwm = velocity_to_pwm(right_velocity)

    # PWM 範囲チェック
    with true <- abs(left_pwm) <= 10_000,
         true <- abs(right_pwm) <= 10_000 do
      # モーター有効化（まだ有効でなければ）
      state = ensure_enabled(state)

      # PWM 書き込み
      IO.write(state.left, "#{left_pwm}")
      IO.write(state.right, "#{right_pwm}")

      Logger.debug("#{__MODULE__}: left_pwm=#{left_pwm}, right_pwm=#{right_pwm}")

      new_state = %{state | left_pwm: left_pwm, right_pwm: right_pwm}

      # タイムアウト付きで返す: @timeout_ms 間メッセージが来なければ handle_info(:timeout) が呼ばれる
      {:reply, :ok, new_state, @timeout_ms}
    else
      _ ->
        Logger.error("#{__MODULE__}: PWM out of range")
        {:reply, {:error, :pwm_out_of_range}, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply,
     %{
       enabled?: state.enabled?,
       left_pwm: state.left_pwm,
       right_pwm: state.right_pwm
     }, state}
  end

  def handle_info(:timeout, state) do
    Logger.info("#{__MODULE__}: timeout - disabling motors")

    IO.write(state.left, "0")
    IO.write(state.right, "0")
    IO.write(state.enable, "0")

    {:noreply, %{state | enabled?: false, left_pwm: 0, right_pwm: 0}}
  end

  # Private

  defp open_device(path) do
    if File.exists?(path) do
      File.open!(path, [:write])
    else
      Logger.warning("#{__MODULE__}: device #{path} not found, using /dev/null")
      File.open!("/dev/null", [:write])
    end
  end

  defp velocity_to_pwm(velocity) do
    round(velocity / (@wheel_dia_meter * :math.pi()) * 400)
  end

  defp ensure_enabled(%{enabled?: true} = state), do: state

  defp ensure_enabled(%{enabled?: false} = state) do
    IO.write(state.enable, "1")
    Logger.info("#{__MODULE__}: motors enabled")
    %{state | enabled?: true}
  end
end
