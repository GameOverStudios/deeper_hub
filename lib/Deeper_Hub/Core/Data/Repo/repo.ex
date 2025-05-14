defmodule Deeper_Hub.Core.Data.Repo do
  @moduledoc """
  Repositório Ecto para o DeeperHub.

  Este módulo é responsável pela interação com o banco de dados SQLite
  através do Ecto, fornecendo uma camada de abstração para operações de
  persistência de dados.
  """

  use Ecto.Repo,
    otp_app: :deeper_hub,
    adapter: Ecto.Adapters.SQLite3

  alias Deeper_Hub.Core.Logger
  
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
        config = Keyword.put(opts, :database, db_path)
        {:ok, config}
      false ->
        # Registra a inicialização do repositório apenas na primeira vez
        Logger.info("Inicializando repositório SQLite", %{module: __MODULE__})
        
        # Marca como inicializado
        :persistent_term.put(@repo_initialized_key, true)
        
        # Define o caminho do banco de dados
        db_path = get_db_path()
        
        # Garante que o diretório existe
        File.mkdir_p!(Path.dirname(db_path))
        
        # Configura o repositório
        config = Keyword.put(opts, :database, db_path)
        
        # Retorna a configuração
        {:ok, config}
    end
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
