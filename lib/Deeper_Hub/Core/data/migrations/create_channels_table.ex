defmodule DeeperHub.Core.Data.Migrations.CreateChannelsTable do
  @moduledoc """
  Migração para criar a tabela de canais no banco de dados.
  
  Esta migração cria a estrutura para armazenar canais de comunicação
  e suas configurações no sistema DeeperHub.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela de canais.
  
  Retorna `:ok` se a migração foi aplicada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de canais...", module: __MODULE__)
    
    sql = """
    CREATE TABLE IF NOT EXISTS channels (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      owner_id TEXT NOT NULL,
      type TEXT DEFAULT 'public',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
    );
    
    CREATE TABLE IF NOT EXISTS channel_members (
      channel_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      role TEXT DEFAULT 'member',
      joined_at TEXT NOT NULL,
      PRIMARY KEY (channel_id, user_id),
      FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    
    CREATE INDEX IF NOT EXISTS idx_channels_name ON channels(name);
    CREATE INDEX IF NOT EXISTS idx_channels_owner ON channels(owner_id);
    CREATE INDEX IF NOT EXISTS idx_channel_members_user ON channel_members(user_id);
    """
    
    case Repo.execute(sql) do
      {:ok, _} -> 
        Logger.info("Tabelas de canais criadas com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} -> 
        Logger.error("Falha ao criar tabelas de canais: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo as tabelas de canais.
  
  Retorna `:ok` se a reversão foi aplicada com sucesso,
  ou `{:error, reason}` se ocorreu algum erro.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabelas de canais...", module: __MODULE__)
    
    sql = """
    DROP TABLE IF EXISTS channel_members;
    DROP TABLE IF EXISTS channels;
    """
    
    case Repo.execute(sql) do
      {:ok, _} -> 
        Logger.info("Tabelas de canais removidas com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} -> 
        Logger.error("Falha ao remover tabelas de canais: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end
