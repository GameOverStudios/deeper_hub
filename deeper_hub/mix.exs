defmodule DeeperHub.MixProject do
  use Mix.Project

  def project do
    [
      app: :deeper_hub,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Configurações para ExDoc
      name: "DeeperHub",
      source_url: "https://github.com/yourusername/deeper_hub",
      homepage_url: "https://yourdomain.com",
      docs: [
        main: "DeeperHub",
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:credo, "~> 1.7"},
      {:dialyxir, "~> 1.4"},
      {:ex_doc, "~> 0.38.1"},
      {:excoveralls, "~> 0.18.5"}
    ]
  end
end
