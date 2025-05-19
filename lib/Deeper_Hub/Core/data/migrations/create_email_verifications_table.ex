defmodule DeeperHub.Core.Data.Migrations.CreateEmailVerificationsTable do
  @moduledoc """
  Migração para criar a tabela de verificações de e-mail.
  
  Esta tabela armazena tokens de verificação de e-mail e seus status,
  permitindo a implementação do fluxo de verificação de e-mail para
  novos usuários ou alterações de e-mail.
  """
  
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  
  @doc """
  Cria a tabela de verificações de e-mail.
  
  Retorna `:ok` se a tabela foi criada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de verificações de e-mail...", module: __MODULE__)
    
    # SQL para criar a tabela de verificações de e-mail
    sql = """
    CREATE TABLE IF NOT EXISTS email_verifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      email TEXT NOT NULL,
      token TEXT NOT NULL UNIQUE,
      expires_at TEXT NOT NULL,
      verified_at TEXT,
      invalidated_at TEXT,
      created_at TEXT NOT NULL
    );
    
    -- Índice para busca rápida por usuário e e-mail
    CREATE INDEX IF NOT EXISTS idx_email_verifications_user_email ON email_verifications (user_id, email);
    
    -- Índice para busca rápida por token
    CREATE INDEX IF NOT EXISTS idx_email_verifications_token ON email_verifications (token);
    
    -- Índice para busca rápida por data de expiração (para limpeza)
    CREATE INDEX IF NOT EXISTS idx_email_verifications_expires_at ON email_verifications (expires_at);
    """
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de verificações de e-mail criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela de verificações de e-mail: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
  
  @doc """
  Remove a tabela de verificações de e-mail.
  
  Retorna `:ok` se a tabela foi removida com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de verificações de e-mail...", module: __MODULE__)
    
    sql = "DROP TABLE IF EXISTS email_verifications;"
    
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela de verificações de e-mail removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela de verificações de e-mail: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
