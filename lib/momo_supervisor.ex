defmodule MomoSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    src_dir_path = "/opt/momo/momo-2022.4.1_raspberry-pi-os_armv8"

    children =
      if Enum.all?([src_dir_path, "/dev/video0"], &File.exists?/1) do
        exec_dir_path = prepare_exec_dir(src_dir_path)

        [
          {MuonTrap.Daemon, [Path.join(exec_dir_path, "momo"), ["test"], [cd: exec_dir_path]]}
        ]
      else
        []
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp prepare_exec_dir(src_dir_path) do
    dst_dir_path = "/usr/momo"

    File.cp_r!(Path.dirname(src_dir_path), dst_dir_path)

    exec_dir_path = Path.join(dst_dir_path, Path.basename(src_dir_path))

    test_html_path = Path.join(exec_dir_path, "html/test.html")
    w350_html_path = Path.join(exec_dir_path, "html/w350.html")

    File.read!(test_html_path)
    |> String.replace("border: 3px solid gray;", "border: 3px solid gray; width: 350px;")
    |> then(&File.write!(w350_html_path, &1))

    exec_dir_path
  end
end
