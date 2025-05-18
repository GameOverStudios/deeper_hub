defmodule DeeperHub.MixProject do
  use Mix.Project

  def project do
    [
      app: :deeper_hub,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DeeperHub.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Para geração de UUIDs
      {:uuid, "~> 1.1"},

      # Source Code
      {:credo, "~> 1.7"},
      {:ex_doc, "~> 0.38.1"},

      # Tests
      {:ex_machina, "~> 2.8.0", only: :test},

      # DBConnection
      {:db_connection, "~> 2.7"},
      {:exqlite, "~> 0.30"},

      # Telemetria e observabilidade
      {:telemetry, "~> 1.3"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.2"},

      # Cache
      {:cachex, "~> 4.1"},

      # Event Bus
      {:event_bus, "~> 1.7.0"},

      # WebSockets e HTTP
      {:cowboy, "~> 2.13"},
      {:plug, "~> 1.17"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},

      # Auth
      {:joken, "~> 2.6"},
      {:guardian, "~> 2.3"},
      {:pbkdf2_elixir, "~> 2.2"}
    ]
  end
end
