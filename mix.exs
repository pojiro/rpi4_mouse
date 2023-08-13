defmodule Rpi4Mouse.MixProject do
  use Mix.Project

  @app :rpi4_mouse
  @version "0.1.0"
  @all_targets [:rpi4_mouse]
  @ui_path "../rpi4_mouse_ui"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.11",
      archives: [nerves_bootstrap: "~> 1.11"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host],
      aliases: aliases(),
      ui_path: @ui_path
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Rpi4Mouse.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets, :ssl, :os_mon],
      included_applications: [:raspimouse2_ex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.10", runtime: false},
      {:shoehorn, "~> 0.9.1"},
      {:ring_logger, "~> 0.10.0"},
      {:toolshed, "~> 0.3.0"},
      {:raspimouse2_ex,
       git: "https://github.com/pojiro/raspimouse2_ex.git", branch: "add-external-api"},
      rpi4_mouse_ui(),

      # Allow Nerves.Runtime on host to support development, testing and CI.
      # See config/host.exs for usage.
      {:nerves_runtime, "~> 0.13.0"},

      # Dependencies for all targets except :host
      {:nerves_pack, "~> 0.7.0", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:nerves_system_rpi4_mouse,
       git: "https://github.com/pojiro/nerves_system_rpi4_mouse.git",
       tag: "v1.22.2+mouse",
       runtime: false,
       targets: :rpi4_mouse}
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end

  defp rpi4_mouse_ui() do
    case {Mix.target(), Mix.env()} do
      {:host, :dev} ->
        {:rpi4_mouse_ui, path: @ui_path, env: Mix.env()}

      _ ->
        {:rpi4_mouse_ui, git: "git@github.com:pojiro/rpi4_mouse_ui.git", env: Mix.env()}
    end
  end

  defp aliases() do
    [
      {:"phx.server", [&compile_ui_for_host/1, "phx.server"]},
      {:"prod.firmware", [&prod_firmware/1]},
      {:"prod.upload", [&prod_upload/1]},
      {:"dev.firmware", [&dev_firmware/1]},
      {:"dev.upload", [&dev_upload/1]}
    ]
  end

  for env <- [:dev, :prod] do
    defp unquote(:"#{env}_firmware")(_) do
      :ok = System.put_env([{"MIX_ENV", unquote(env)}, {"MIX_TARGET", "rpi4_mouse"}])
      firmware_impl!()
    end

    defp unquote(:"#{env}_upload")(args) do
      :ok = System.put_env([{"MIX_ENV", unquote(env)}, {"MIX_TARGET", "rpi4_mouse"}])
      upload_impl!(args)
    end
  end

  defp firmware_impl!() do
    0 = Mix.shell().cmd("mix deps.get")
    0 = Mix.shell().cmd("mix ui.compile", cd: "deps/rpi4_mouse_ui")
    0 = Mix.shell().cmd("mix deps.compile")
    0 = Mix.shell().cmd("mix firmware")
  end

  defp compile_ui_for_host(args) when is_list(args) do
    Mix.shell().cmd("mix ui.compile", cd: @ui_path)
  end

  defp upload_impl!(args) when is_list(args) do
    0 = Mix.shell().cmd("mix upload #{Enum.join(args, " ")}")
  end
end
