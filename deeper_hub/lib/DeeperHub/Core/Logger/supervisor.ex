defmodule DeeperHub.Core.Logger.Supervisor do
  @moduledoc """
  Supervisor para os processos relacionados ao Logger.
  """

  use Supervisor

  def start_link(init_arg) do
    IO.puts(" ⚙️  Iniciando Logger")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Configura o Logger do Elixir para mostrar cores e metadados
    configure_logger()

    children = [
      # Por enquanto não tem processos filhos, mas poderíamos adicionar aqui
      # Um worker para processar logs assincronamente, por exemplo
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Configura o Logger do Elixir para trabalhar bem com nosso logger personalizado
  defp configure_logger do
    # Garantir que o Logger do Elixir mostre cores no console
    Application.put_env(:logger, :console,
      colors: [
        enabled: true,
        debug: :cyan,
        info: :green,
        warning: :yellow,
        error: :red
      ],
      format: "$time $metadata[$level] $message\n",
      metadata: [:user_id, :request_id]
    )

    # Define o nível mínimo de log
    Logger.configure(level: :debug)
  end
end
