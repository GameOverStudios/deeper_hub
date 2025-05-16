defmodule Deeper_Hub.Core.Data.Repo do
  @moduledoc """
  Repositório Ecto para o Deeper_Hub.

  Este módulo é responsável pela interação com o banco de dados SQLite
  através do Ecto, fornecendo uma camada de abstração para operações de
  persistência de dados.

  Utiliza a biblioteca DBConnection para gerenciar um pool de conexões,
  permitindo melhor desempenho e utilização de recursos.
  """

  use Ecto.Repo,
    otp_app: :deeper_hub,
    adapter: Ecto.Adapters.SQLite3

  alias Deeper_Hub.Core.Logger
  # Removido alias não utilizado

  # Chave para controlar a inicialização do repositório
  @repo_initialized_key {__MODULE__, :initialized}

  @doc """
  Inicializa o repositório com as configurações apropriadas.

  ## Parâmetros

    - `opts`: Opções adicionais para a inicialização do repositório

  ## Retorno

    - Resultado da inicialização do repositório
  """
  def init(_, opts) do
    # Verifica se o repositório já foi inicializado neste processo
    case :persistent_term.get(@repo_initialized_key, false) do
      true ->
        # Se já foi inicializado, apenas retorna a configuração sem log
        db_path = get_db_path()
        config = configure_repo(opts, db_path)
        {:ok, config}
      false ->
        # Registra a inicialização do repositório apenas na primeira vez
        Logger.info("Inicializando repositório SQLite com pool de conexões", %{module: __MODULE__})

        # Marca como inicializado
        :persistent_term.put(@repo_initialized_key, true)

        # Define o caminho do banco de dados
        db_path = get_db_path()

        # Garante que o diretório existe
        File.mkdir_p!(Path.dirname(db_path))

        # Configura o repositório com o pool de conexões
        config = configure_repo(opts, db_path)

        # Registra as configurações de pool
        Logger.info("Pool de conexões configurado", %{
          module: __MODULE__,
          pool_size: Keyword.get(config, :pool_size, 10),
          queue_target: Keyword.get(config, :queue_target, 50),
          queue_interval: Keyword.get(config, :queue_interval, 1000)
        })

        # Retorna a configuração
        {:ok, config}
    end
  end

  # Configura o repositório com as configurações de pool otimizadas
  defp configure_repo(opts, db_path) do
    # Configurações padrão para o pool de conexões
    pool_config = [
      # Tamanho do pool - número de conexões mantidas abertas
      pool_size: 10,

      # Tempo máximo (em ms) que uma requisição deve esperar por uma conexão
      queue_target: 50,

      # Intervalo (em ms) para verificar o tamanho da fila
      queue_interval: 1000,

      # Tempo (em ms) para manter conexões ociosas abertas
      idle_interval: 300_000,

      # Configurações de telemetria para monitoramento
      telemetry_prefix: [:deeper_hub, :repo],

      # Timeout para operações de checkout (obtenção de conexão do pool)
      timeout: 15_000,

      # Timeout para operações de consulta
      ownership_timeout: 60_000
    ]

    # Mescla as configurações padrão com as fornecidas e adiciona o caminho do banco
    opts
    |> Keyword.merge(pool_config)
    |> Keyword.put(:database, db_path)
  end

  # Função auxiliar para obter o caminho do banco de dados
  defp get_db_path do
    case Mix.env() do
      :test -> "database/test.db"
      :dev -> "database/dev.db"
      _ -> "database/prod.db"
    end
  end
end
