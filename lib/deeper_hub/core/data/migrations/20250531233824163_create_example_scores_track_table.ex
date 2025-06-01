# Migração gerada com ID único: V1748745504163 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateExampleScoresTrackTable do
  # Migração gerada com ID único: V1748745504163 em 2025-05-31 23:38:24
  @moduledoc """
  Migração EXEMPLO para criar uma tabela de rastreamento de scores.
  O nome real da tabela viria de sys_objects_score.table_track.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @table_name "example_scores_track" # Este nome seria dinâmico

  @doc """
  Executa a migração para criar a tabela de exemplo.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela de exemplo de rastreamento de scores: #{@table_name}...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- ID do item de conteúdo pontuado
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id
      author_nip INTEGER NOT NULL, -- IP do autor como inteiro
      type TEXT NOT NULL CHECK(type IN ('up', 'down')), -- 'up' ou 'down'
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- A FK para object_id dependeria do tipo de conteúdo.
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_#{@table_name}_object_author ON #{@table_name}(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_author_id ON #{@table_name}(author_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_type ON #{@table_name}(object_id, type);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{@table_name} criada com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao criar tabela #{@table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela de exemplo.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela #{@table_name}...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS #{@table_name};"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela #{@table_name} removida com sucesso.", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error("Falha ao remover tabela #{@table_name}: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end
end