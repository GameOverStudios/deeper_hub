# Migração gerada com ID único: V1748745503982 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateSysFilesTable do
  # Migração gerada com ID único: V1748745503982 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela genérica de metadados de arquivos sys_files.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @spec up() :: :ok | {:error, any()}
  def up do
    # O nome real da tabela seria definido em sys_objects_storage.table_files.
    # Usamos "sys_files" aqui como um exemplo comum.
    table_name = "sys_files"
    Logger.info("Criando tabela #{table_name} (exemplo genérico)...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS #{table_name} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL, -- sys_profiles.id do uploader
      remote_id TEXT NOT NULL UNIQUE, -- Identificador no storage físico (ex: S3 key, UUID.ext)
      path TEXT NOT NULL, -- Caminho relativo no storage ou bucket/prefixo
      file_name TEXT NOT NULL, -- Nome original do arquivo enviado pelo usuário
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL, -- Em bytes
      -- dimensions TEXT, -- Opcional: "larguraxaltura" para imagens
      -- duration INTEGER, -- Opcional: em segundos para áudio/vídeo
      added INTEGER NOT NULL, -- Unix Timestamp
      modified INTEGER NOT NULL, -- Unix Timestamp
      private INTEGER NOT NULL DEFAULT 0, -- 0 para público, 1 para privado
      -- content_id INTEGER, -- Opcional: ID do conteúdo ao qual este arquivo está associado
      -- content_module TEXT -- Opcional: Módulo do conteúdo associado
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL -- ou ON DELETE CASCADE dependendo da política
    );
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_profile_id ON #{table_name}(profile_id);
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_remote_id ON #{table_name}(remote_id);
    -- CREATE INDEX IF NOT EXISTS idx_#{table_name}_content ON #{table_name}(content_module, content_id); -- Se usar content_id/module
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{table_name} criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela #{table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @spec down() :: :ok | {:error, any()}
  def down do
    table_name = "sys_files"
    Logger.info("Removendo tabela #{table_name}...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS #{table_name};"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{table_name} removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela #{table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end