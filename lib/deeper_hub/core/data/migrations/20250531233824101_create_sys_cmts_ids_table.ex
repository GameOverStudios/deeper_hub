# Migração gerada com ID único: V1748745504100 em 2025-05-31 23:38:24
defmodule DeeperHub.Core.Data.Migrations.CreateSysCmtsIdsTable do
  # Migração gerada com ID único: V1748745504100 em 2025-05-31 23:38:24
  @moduledoc """
  Migração para criar a tabela sys_cmts_ids.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela sys_cmts_ids.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela sys_cmts_ids...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS sys_cmts_ids (
      id INTEGER PRIMARY KEY AUTOINCREMENT, -- PK interna desta tabela
      system_id INTEGER NOT NULL, -- FK para sys_objects_cmts.ID
      cmt_id INTEGER NOT NULL, -- ID do comentário na sua tabela de conteúdo
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id
      rate REAL NOT NULL DEFAULT 0,
      votes INTEGER NOT NULL DEFAULT 0,
      rrate REAL NOT NULL DEFAULT 0,
      rvotes INTEGER NOT NULL DEFAULT 0,
      score INTEGER NOT NULL DEFAULT 0,
      sc_up INTEGER NOT NULL DEFAULT 0,
      sc_down INTEGER NOT NULL DEFAULT 0,
      reports INTEGER NOT NULL DEFAULT 0,
      status_admin TEXT NOT NULL DEFAULT 'active' CHECK(status_admin IN ('active', 'hidden', 'pending')),
      FOREIGN KEY (system_id) REFERENCES sys_objects_cmts(ID) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_cmts_ids_system_cmt ON sys_cmts_ids(system_id, cmt_id);
    CREATE INDEX IF NOT EXISTS idx_sys_cmts_ids_author_id ON sys_cmts_ids(author_id);
    CREATE INDEX IF NOT EXISTS idx_sys_cmts_ids_cmt_id ON sys_cmts_ids(cmt_id); -- Útil para buscar metadados de um cmt_id específico
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_cmts_ids criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela sys_cmts_ids: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela sys_cmts_ids.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela sys_cmts_ids...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS sys_cmts_ids;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela sys_cmts_ids removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela sys_cmts_ids: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
