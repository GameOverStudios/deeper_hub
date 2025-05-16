defmodule Deeper_Hub.MixProject do
  use Mix.Project

  def project do
    [
      app: :deeper_hub,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Configurações para ExDoc
      name: "Deeper_Hub",
      source_url: "https://github.com/yourusername/deeper_hub",
      homepage_url: "https://yourdomain.com",
      docs: [
        main: "Deeper_Hub",
        extras: [
          "README.md",
          {"../Coding.md", [title: "Diretrizes de Codificação"]}
        ]
      ],
      # Configurações para ExCoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      # Configurações para Dialyxir
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mnesia],
      mod: {Deeper_Hub.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},       # Para geração de UUIDs
      {:jason, "~> 1.4"},      # Para codificação/decodificação JSON

      # Source Code
      {:credo, "~> 1.7"},
      {:ex_doc, "~> 0.38.1"},

      # Data
      {:ecto, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.17"},
      {:db_connection, "~> 2.7"},
      {:scrivener, "~> 2.7"},
      {:scrivener_ecto, "~> 3.1"},

      # Telemetria e observabilidade
      {:telemetry, "~> 1.3"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.2"},

      # Eventos
      {:event_bus, "~> 1.7"},

      # Cache
      {:cachex, "~> 4.1"},

      # Circuit Break
      {:ex_break, "~> 0.0"},

      # Protocol Buffers
      {:protobuf, "~> 0.14.1"},

      # Phoenix para WebSocket
      {:phoenix, "~> 1.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:plug_cowboy, "~> 2.7.3"},
    ]
  end
end
