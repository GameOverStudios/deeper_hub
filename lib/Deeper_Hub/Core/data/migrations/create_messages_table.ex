defmodule DeeperHub.Core.Data.Migrations.CreateMessagesTable do
  @moduledoc """
  Migração para criar a tabela de mensagens no banco de dados.
  
  Esta migração cria a estrutura para armazenar mensagens trocadas entre
  usuários ou em canais no sistema DeeperHub.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela de mensagens.
  
  Retorna `:ok` se a migração foi aplicada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de mensagens...", module: __MODULE__)
    
    sql = """
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      sender_id TEXT NOT NULL,
      recipient_id TEXT,
      channel_id TEXT,
      content TEXT NOT NULL,
      content_type TEXT DEFAULT 'text',
      status TEXT DEFAULT 'sent',
      read_at TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE,
      CHECK ((recipient_id IS NULL AND channel_id IS NOT NULL) OR (recipient_id IS NOT NULL AND channel_id IS NULL))
    );
    
    CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
    CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id);
    CREATE INDEX IF NOT EXISTS idx_messages_channel ON messages(channel_id);
    CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
    """
    
    case Repo.execute(sql) do
      {:ok, _} -> 
        Logger.info("Tabela de mensagens criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} -> 
        Logger.error("Falha ao criar tabela de mensagens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela de mensagens.
  
  Retorna `:ok` se a reversão foi aplicada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela de mensagens...", module: __MODULE__)
    
    sql = """
    DROP TABLE IF EXISTS messages;
    """
    
    case Repo.execute(sql) do
      {:ok, _} -> 
        Logger.info("Tabela de mensagens removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} -> 
        Logger.error("Falha ao remover tabela de mensagens: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
