# Migração gerada com ID único: V1748745504167 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysObjectsScoreTable do
  # Migração gerada com ID único: V1748745504167 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_objects_score.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_objects_score.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_objects_score...", module: __MODULE__)

    sql = """
    CREATE TABLE IF NOT EXISTS sys_objects_score (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      table_main TEXT NOT NULL, -- Tabela de sumário dos scores
      table_track TEXT NOT NULL, -- Tabela de rastreamento de scores
      post_timeout INTEGER NOT NULL DEFAULT 0,
      pruning INTEGER NOT NULL DEFAULT 31536000, -- 1 ano em segundos
      is_undo INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se score pode ser desfeito/alterado)
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT,
      trigger_field_score TEXT, -- Coluna para score total (up - down)
      trigger_field_cup TEXT, -- Coluna para contagem de upvotes
      trigger_field_cdown TEXT, -- Coluna para contagem de downvotes
      class_name TEXT,
      class_file TEXT
      -- FK para Module (sys_modules.name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_score_name ON sys_objects_score(name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_score_module ON sys_objects_score(Module);
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_score criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_objects_score: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_objects_score.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_objects_score...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_objects_score;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_objects_score removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_objects_score: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
