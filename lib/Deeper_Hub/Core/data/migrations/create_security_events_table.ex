defmodule DeeperHub.Core.Data.Migrations.CreateSecurityEventsTable do
  @moduledoc """
  Migração para criar a tabela de eventos de segurança.
  
  Esta tabela armazena eventos relacionados à segurança do sistema,
  como tentativas de autenticação bloqueadas, atividades suspeitas,
  bloqueios de IP e outros eventos relevantes para a segurança.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Cria a tabela de eventos de segurança.
  
  Retorna `:ok` se a tabela foi criada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de eventos de segurança...", module: __MODULE__)
    
    # SQL para criar a tabela de eventos de segurança
    sql = """
    CREATE TABLE IF NOT EXISTS security_events (
      id TEXT PRIMARY KEY,
      event_type TEXT NOT NULL,
      user_id TEXT,
      details TEXT NOT NULL,
      ip_address TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    
    -- Índice para busca rápida por tipo de evento
    CREATE INDEX IF NOT EXISTS idx_security_events_event_type ON security_events (event_type);
    
    -- Índice para busca rápida por IP
    CREATE INDEX IF NOT EXISTS idx_security_events_ip_address ON security_events (ip_address);
    
    -- Índice para busca rápida por usuário (quando não for nulo)
    CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON security_events (user_id) WHERE user_id IS NOT NULL;
    
    -- Índice para busca rápida por data de criação
    CREATE INDEX IF NOT EXISTS idx_security_events_created_at ON security_events (created_at);
    """
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de eventos de segurança criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de eventos de segurança: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  @doc """
  Remove a tabela de eventos de segurança.
  
  Retorna `:ok` se a tabela foi removida com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de eventos de segurança...", module: __MODULE__)
    
    sql = "DROP TABLE IF EXISTS security_events;"
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de eventos de segurança removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de eventos de segurança: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
