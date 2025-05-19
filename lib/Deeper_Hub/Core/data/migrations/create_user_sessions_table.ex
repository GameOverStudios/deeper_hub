defmodule DeeperHub.Core.Data.Migrations.CreateUserSessionsTable do
  @moduledoc """
  Migração para criar a tabela de sessões de usuário.
  
  Esta tabela armazena informações sobre sessões ativas de usuários,
  permitindo o gerenciamento de múltiplas sessões por usuário e
  implementação de recursos como "lembrar-me" e timeout por inatividade.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Cria a tabela de sessões de usuário.
  
  Retorna `:ok` se a tabela foi criada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de sessões de usuário...", module: __MODULE__)
    
    # SQL para criar a tabela de sessões de usuário
    sql = """
    CREATE TABLE IF NOT EXISTS user_sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      refresh_token_jti TEXT NOT NULL,
      device_info TEXT,
      ip_address TEXT NOT NULL,
      user_agent TEXT,
      persistent BOOLEAN DEFAULT FALSE,
      last_activity_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    
    -- Índice para busca rápida por usuário
    CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions (user_id);
    
    -- Índice para busca rápida por data de expiração (para limpeza)
    CREATE INDEX IF NOT EXISTS idx_user_sessions_expires_at ON user_sessions (expires_at);
    
    -- Índice para busca rápida por última atividade (para timeout por inatividade)
    CREATE INDEX IF NOT EXISTS idx_user_sessions_last_activity ON user_sessions (last_activity_at);
    
    -- Índice para busca rápida por JTI do token de refresh
    CREATE INDEX IF NOT EXISTS idx_user_sessions_refresh_token ON user_sessions (refresh_token_jti);
    """
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sessões de usuário criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de sessões de usuário: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  @doc """
  Remove a tabela de sessões de usuário.
  
  Retorna `:ok` se a tabela foi removida com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de sessões de usuário...", module: __MODULE__)
    
    sql = "DROP TABLE IF EXISTS user_sessions;"
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de sessões de usuário removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de sessões de usuário: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
