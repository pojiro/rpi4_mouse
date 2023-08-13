import Config

#
# phoenix config.exs
#

# Configures the endpoint
config :rpi4_mouse_ui, Rpi4MouseUiWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: Rpi4MouseUiWeb.ErrorHTML, json: Rpi4MouseUiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Rpi4MouseUi.PubSub,
  live_view: [signing_salt: "GP3VRFMz"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../#{Mix.Project.config()[:ui_path]}/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../#{Mix.Project.config()[:ui_path]}/assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

#
# phoenix dev.exs
#

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :rpi4_mouse_ui, Rpi4MouseUiWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "T5BhQQHaBRUuY8NxppaaD/q5cDdcibJPZilnGF06wbLZrcm3oHAqkHrI30S6WhVe",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :rpi4_mouse_ui, Rpi4MouseUiWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/rpi4_mouse_ui_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :rpi4_mouse_ui, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

#
# phoenix prod.exs
#

# # Note we also include the path to a cache manifest
# # containing the digested version of static files. This
# # manifest is generated by the `mix assets.deploy` task,
# # which you should run after static files are built and
# # before starting your production server.
# config :rpi4_mouse_ui, Rpi4MouseUiWeb.Endpoint,
#   cache_static_manifest: "priv/static/cache_manifest.json"
# 
# # Do not print debug messages in production
# config :logger, level: :info
# 
# # Runtime production configuration, including reading
# # of environment variables, is done on config/runtime.exs.

#
# phoenix partial runtime.exs
#

# config :rpi4_mouse_ui, Rpi4MouseUiWeb.Endpoint, server: true

#
# custom
#

# See. https://github.com/phoenixframework/phoenix_live_reload#backends
# This setting is not written in document, only in README.md.
config :phoenix_live_reload,
  dirs: [
    "#{Mix.Project.config()[:ui_path]}/priv/static",
    "#{Mix.Project.config()[:ui_path]}/priv/gettext",
    "#{Mix.Project.config()[:ui_path]}/lib/rpi4_mouse_ui_web/controllers",
    "#{Mix.Project.config()[:ui_path]}/lib/rpi4_mouse_ui_web/live",
    "#{Mix.Project.config()[:ui_path]}/lib/rpi4_mouse_ui_web/components"
  ]
