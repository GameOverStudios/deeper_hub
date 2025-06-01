# Migração gerada com ID único: V1748745504342 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysPermalinksTable do
  # Migração gerada com ID único: V1748745504342 em 2025-05-31 23:38:24
  @moduledoc "Migração para criar a tabela sys_permalinks."
  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  def up do
    Logger.info("Criando tabela sys_permalinks...", module: __MODULE__)
    sql = """
    CREATE TABLE IF NOT EXISTS sys_permalinks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      standard TEXT NOT NULL,
      permalink TEXT NOT NULL,
      "check" TEXT NOT NULL,
      compare_by_prefix INTEGER NOT NULL DEFAULT 0
    );

    CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_permalinks_permalink ON sys_permalinks(permalink);
    CREATE INDEX IF NOT EXISTS idx_sys_permalinks_standard ON sys_permalinks(standard);
    CREATE INDEX IF NOT EXISTS idx_sys_permalinks_check ON sys_permalinks("check");
    """
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_permalinks criada com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao criar tabela sys_permalinks: #{inspect(reason)}", module: __MODULE__)
    end)
  end

  def down do
    Logger.info("Removendo tabela sys_permalinks...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_permalinks;"
    Repo.execute(sql)
    |> tap(fn
      {:ok, _} -> Logger.info("Tabela sys_permalinks removida com sucesso.", module: __MODULE__)
      {:error, reason} -> Logger.error("Falha ao remover tabela sys_permalinks: #{inspect(reason)}", module: __MODULE__)
    end)
  end
end