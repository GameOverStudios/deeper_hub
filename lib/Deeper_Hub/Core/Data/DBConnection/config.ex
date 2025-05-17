defmodule Deeper_Hub.Core.Data.DBConnection.Config do
  @moduledoc """
  Configurações para o DBConnection.
  
  Este módulo fornece as configurações necessárias para o DBConnection,
  incluindo opções de pool e conexão.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Retorna as configurações do pool de conexões para o ambiente atual.
  
  ## Retorno
  
    - Mapa com as configurações do pool de conexões
  """
  @spec get_pool_config() :: map()
  def get_pool_config do
    # Usa o ambiente atual sem gerar log redundante
    get_pool_config(Mix.env())
  end
  
  @doc """
  Retorna as configurações do pool de conexões para um ambiente específico.
  
  ## Parâmetros
  
    - `env`: O ambiente para o qual obter as configurações (:test, :dev, :prod)
  
  ## Retorno
  
    - Mapa com as configurações do pool de conexões
  """
  @spec get_pool_config(atom()) :: map()
  def get_pool_config(env) do
    # Reduzimos o nível de log para evitar mensagens duplicadas
    Logger.debug("Obtendo configurações do pool de conexões", %{
      module: __MODULE__,
      env: env
    })
    
    # Define as configurações do pool com base no ambiente
    pool_size = case env do
      :test -> 2
      :dev -> 5
      _ -> 10
    end
    
    max_overflow = case env do
      :test -> 0
      :dev -> 2
      _ -> 5
    end
    
    # Retorna as configurações
    %{
      pool_size: pool_size,
      max_overflow: max_overflow,
      idle_interval: 1000,
      queue_target: 50,
      queue_interval: 1000
    }
  end
  
  @doc """
  Retorna as configurações de conexão para o ambiente atual.
  
  ## Retorno
  
    - Mapa com as configurações de conexão
  """
  @spec get_connection_config() :: map()
  def get_connection_config do
    # Usa o ambiente atual sem gerar log redundante
    get_connection_config(Mix.env())
  end
  
  @doc """
  Retorna as configurações de conexão para um ambiente específico.
  
  ## Parâmetros
  
    - `env`: O ambiente para o qual obter as configurações (:test, :dev, :prod)
  
  ## Retorno
  
    - Mapa com as configurações de conexão
  """
  @spec get_connection_config(atom()) :: map()
  def get_connection_config(env) do
    # Reduzimos o nível de log para evitar mensagens duplicadas
    Logger.debug("Obtendo configurações de conexão", %{
      module: __MODULE__,
      env: env
    })
    
    # Define o caminho do banco de dados com base no ambiente
    db_path = case env do
      :test -> "database/test.db"
      :dev -> "database/dev.db"
      _ -> "database/prod.db"
    end
    
    # Retorna as configurações
    %{
      database: db_path
    }
  end
  
  @doc """
  Configura o banco de dados para o ambiente atual.
  
  ## Retorno
  
    - `:ok` se a configuração for bem-sucedida
    - `{:error, reason}` em caso de falha
  """
  @spec configure() :: :ok | {:error, term()}
  def configure do
    try do
      # Obtém as configurações
      config = get_connection_config()
      
      # Garante que o diretório do banco de dados existe
      File.mkdir_p!(Path.dirname(config.database))
      
      # Verifica se o banco de dados existe
      db_exists = File.exists?(config.database)
      
      # Registra o status do banco de dados com nível de log mais adequado
      if db_exists do
        Logger.debug("Banco de dados encontrado", %{
          module: __MODULE__,
          database: config.database
        })
      else
        # Mantemos como info apenas a criação de um novo banco, que é um evento importante
        Logger.info("Banco de dados não encontrado, será criado", %{
          module: __MODULE__,
          database: config.database
        })
      end
      
      :ok
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao configurar o banco de dados", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Verifica se o banco de dados existe.
  
  ## Parâmetros
  
    - `config`: Mapa com as configurações de conexão
  
  ## Retorno
  
    - `true` se o banco de dados existir
    - `false` se o banco de dados não existir
  """
  @spec database_exists?(map()) :: boolean()
  def database_exists?(config) do
    # Verifica se o arquivo do banco de dados existe
    File.exists?(config.database)
  end
end
