defmodule DeeperHub.MixProject do
  use Mix.Project

  def project do
    [
      app: :deeper_hub,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Configurações para compilação e distribuição
      releases: releases(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      test_coverage: [
        tool: ExCoveralls
      ]
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38.1", only: :dev, runtime: false},

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
      {:cors_plug, "~> 3.0"},

      # Auth
      {:joken, "~> 2.6"},
      {:guardian, "~> 2.3"},
      {:pbkdf2_elixir, "~> 2.2"},

      # Segurança
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:plug_attack, "~> 0.4"},
    ]
  end

  # Configurações para releases
  defp releases do
    [
      deeper_hub: [
        include_executables_for: [:unix, :windows],
        applications: [
          runtime_tools: :permanent
        ],
        steps: [:assemble, :tar],
        # Configurações específicas para produção
        cookie: System.get_env("RELEASE_COOKIE") || "deeper_hub_release_cookie",
        config_providers: [
          {Config.Reader,
            file: System.get_env("RELEASE_CONFIG_FILE") || "${RELEASE_ROOT}/config/runtime.exs"}
        ]
      ]
    ]
  end
end
