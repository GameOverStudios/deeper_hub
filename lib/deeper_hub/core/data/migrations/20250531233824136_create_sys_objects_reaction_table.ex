# Migração gerada com ID único: V1748745504135 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsReactionTable do
  # Migração gerada com ID único: V1748745504135 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela de configuração sys_objects_reaction (hipotética).
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_reaction.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_reaction (hipotética)...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_reaction (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      reactions_available TEXT NOT NULL DEFAULT '["like", "love", "haha", "wow", "sad", "angry"]', -- JSON array ou string CSV
      table_summary TEXT NOT NULL, -- Tabela de sumário de reações
      table_track TEXT NOT NULL, -- Tabela de rastreamento de reações
      is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se reação pode ser desfeita/alterada)
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_reactions_count TEXT, -- Coluna para contagem total ou JSON de contagens por tipo
      class_name TEXT,
      class_file TEXT
      -- FK para Module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_name ON sys_objects_reaction(name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_module ON sys_objects_reaction(Module);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_reaction criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_reaction: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_reaction.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_reaction...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_reaction;"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_reaction removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_reaction: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end