defmodule DeeperHub.Core.Data.Migrations.CreateRevokedTokensTable do
  @moduledoc """
  Migração para criar a tabela de tokens revogados.
  
  Esta tabela armazena informações sobre tokens JWT que foram revogados
  antes de sua expiração natural, garantindo que não possam ser reutilizados.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Cria a tabela de tokens revogados.
  
  Retorna `:ok` se a tabela foi criada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de tokens revogados...", module: __MODULE__)
    
    # SQL para criar a tabela de tokens revogados
    sql = """
    CREATE TABLE IF NOT EXISTS revoked_tokens (
      jti TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      token_type TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      revoked_at TEXT NOT NULL,
      reason TEXT
    );
    
    -- Índice para busca rápida por usuário
    CREATE INDEX IF NOT EXISTS idx_revoked_tokens_user_id ON revoked_tokens (user_id);
    
    -- Índice para busca rápida por data de expiração (para limpeza)
    CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires_at ON revoked_tokens (expires_at);
    """
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de tokens revogados criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de tokens revogados: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  @doc """
  Remove a tabela de tokens revogados.
  
  Retorna `:ok` se a tabela foi removida com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de tokens revogados...", module: __MODULE__)
    
    sql = "DROP TABLE IF EXISTS revoked_tokens;"
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de tokens revogados removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de tokens revogados: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
