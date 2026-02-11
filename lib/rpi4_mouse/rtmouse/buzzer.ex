defmodule Rpi4Mouse.Rtmouse.Buzzer do
  use GenServer

  require Logger

  @min_freq 0
  @max_freq 20_000

  # API

  @spec beep(msg :: map()) :: :ok | {:error, atom()}
  def beep(%{data: hz} = _msg) do
    GenServer.call(__MODULE__, {:beep, hz})
  end

  @spec get_tone() :: integer()
  def get_tone() do
    GenServer.call(__MODULE__, :get_tone)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # Callbacks

  def init(args) do
    Process.flag(:trap_exit, true)

    dev_buzzer = Keyword.fetch!(args, :buzzer_device)
    device = open_device(dev_buzzer)

    # 初期状態: ブザーオフ（0Hz）
    IO.write(device, "0")

    {:ok, %{device: device, hz: 0}}
  end

  def terminate(reason, state) do
    Logger.error("#{__MODULE__}: terminated by #{inspect(reason)}.")

    # 終了時は必ずブザーを停止
    IO.write(state.device, "0")
    File.close(state.device)
  end

  def handle_call({:beep, hz}, _from, state) do
    # 周波数範囲チェック
    with true <- is_integer(hz),
         true <- @min_freq <= hz and hz <= @max_freq do
      # 周波数書き込み
      IO.write(state.device, "#{hz}")
      {:reply, :ok, %{state | hz: hz}}
    else
      false ->
        Logger.error("#{__MODULE__}: frequency out of range (#{@min_freq}-#{@max_freq} Hz)")
        {:reply, {:error, :invalid_frequency}, state}
    end
  end

  def handle_call(:get_tone, _from, state) do
    {:reply, state.hz, state}
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
end
