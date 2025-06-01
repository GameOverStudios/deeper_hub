# Migração gerada com ID único: V1748745503835 em 2025-05-31 23:38:23
defmodule DeeperHub.Core.Data.Migrations.CreateBxPersonsCmtsTable do
  # Migração gerada com ID único: V1748745503835 em 2025-05-31 23:38:23
  @moduledoc """
  Migração para criar a tabela bx_persons_cmts (se aplicável).
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Executa a migração para criar a tabela bx_persons_cmts.
  """
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info("Criando tabela bx_persons_cmts (condicional)...", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = """
    CREATE TABLE IF NOT EXISTS bx_persons_cmts (
      cmt_id INTEGER PRIMARY KEY AUTOINCREMENT,
      cmt_parent_id INTEGER NOT NULL DEFAULT 0,
      cmt_vparent_id INTEGER NOT NULL DEFAULT 0,
      cmt_object_id INTEGER NOT NULL, -- FK para sys_profiles.id (perfil comentado)
      cmt_author_id INTEGER NOT NULL, -- FK para sys_profiles.id (autor do comentário)
      cmt_level INTEGER NOT NULL DEFAULT 0,
      cmt_text TEXT NOT NULL,
      cmt_mood INTEGER NOT NULL DEFAULT 0, -- TINYINT(4)
      cmt_rate INTEGER NOT NULL DEFAULT 0,
      cmt_rate_count INTEGER NOT NULL DEFAULT 0,
      cmt_time INTEGER NOT NULL, -- Unix Timestamp
      cmt_replies INTEGER NOT NULL DEFAULT 0,
      cmt_pinned INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      cmt_cf INTEGER NOT NULL DEFAULT 1, -- Content Filter ID?
      FOREIGN KEY (cmt_object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (cmt_author_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE -- ou RESTRICT se autor não pode ser nulo
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_object_parent ON bx_persons_cmts(cmt_object_id, cmt_parent_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_author_id ON bx_persons_cmts(cmt_author_id);
    -- FULLTEXT KEY search_fields (cmt_text) do MySQL -> Usar FTS do SQLite se necessário.
    """

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_cmts criada com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao criar tabela bx_persons_cmts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  @doc """
  Reverte a migração, removendo a tabela bx_persons_cmts.
  """
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info("Removendo tabela bx_persons_cmts...", module: __MODULE__)
    sql = "DROP TABLE IF EXISTS bx_persons_cmts;"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info("Tabela bx_persons_cmts removida com sucesso.", module: __MODULE__)
        :ok

      {:error, reason} ->
        Logger.error("Falha ao remover tabela bx_persons_cmts: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end
end
