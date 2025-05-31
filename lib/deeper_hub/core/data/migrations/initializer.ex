defmodule DeeperHub.Core.Data.Migrations.Initializer do
  @moduledoc """
  Módulo responsável por inicializar o banco de dados antes da execução das migrações.
  
  Este módulo garante que o diretório do banco de dados exista e que o arquivo do banco
  seja criado corretamente antes de executar qualquer migração.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Inicializa o banco de dados, garantindo que o diretório exista e que o arquivo
  do banco seja criado corretamente.
  
  Retorna `:ok` se a inicialização foi bem-sucedida ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec initialize() :: :ok | {:error, any()}
  def initialize do
    Logger.info("Inicializando banco de dados...", module: __MODULE__)
    
    # Obtém o caminho do banco de dados da configuração
    db_config = Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
    db_path = Keyword.get(db_config, :database, "databases/deeper_hub_dev.db")
    
    # Garante que o diretório do banco de dados exista
    with :ok <- ensure_db_directory(db_path),
         :ok <- ensure_db_file(db_path) do
      
      Logger.info("Banco de dados inicializado com sucesso em: #{db_path}", module: __MODULE__)
      :ok
    else
      {:error, reason} = error ->
        Logger.error("Falha ao inicializar banco de dados: #{inspect(reason)}", module: __MODULE__)
        error
    end
  end

  @doc """
  Garante que o diretório do banco de dados exista.
  Se o diretório não existir, tenta criá-lo.
  
  Retorna `:ok` se o diretório já existe ou foi criado com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec ensure_db_directory(String.t()) :: :ok | {:error, any()}
  def ensure_db_directory(db_path) do
    db_dir = Path.dirname(db_path)
    
    Logger.debug("Verificando diretório do banco de dados: #{db_dir}", module: __MODULE__)
    
    case File.dir?(db_dir) do
      true ->
        Logger.debug("Diretório do banco de dados já existe: #{db_dir}", module: __MODULE__)
        :ok
      false ->
        Logger.info("Criando diretório do banco de dados: #{db_dir}", module: __MODULE__)
        case File.mkdir_p(db_dir) do
          :ok -> 
            Logger.info("Diretório do banco de dados criado com sucesso: #{db_dir}", module: __MODULE__)
            :ok
          {:error, reason} = error -> 
            Logger.error("Falha ao criar diretório do banco de dados: #{inspect(reason)}", module: __MODULE__)
            error
        end
    end
  end

  @doc """
  Garante que o arquivo do banco de dados exista.
  Se o arquivo não existir, tenta criá-lo.
  
  Retorna `:ok` se o arquivo já existe ou foi criado com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec ensure_db_file(String.t()) :: :ok | {:error, any()}
  def ensure_db_file(db_path) do
    Logger.debug("Verificando arquivo do banco de dados: #{db_path}", module: __MODULE__)
    
    case File.exists?(db_path) do
      true ->
        Logger.debug("Arquivo do banco de dados já existe: #{db_path}", module: __MODULE__)
        :ok
      false ->
        Logger.info("Arquivo do banco de dados não encontrado. Será criado automaticamente na primeira conexão.", module: __MODULE__)
        # O arquivo será criado automaticamente pelo SQLite na primeira conexão
        :ok
    end
  end
end
