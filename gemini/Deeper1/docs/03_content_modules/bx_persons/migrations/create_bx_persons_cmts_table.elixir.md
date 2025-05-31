# Migração Elixir: Criar Tabela `bx_persons_cmts`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_cmts` no banco de dados SQLite. Esta tabela armazena comentários feitos em perfis de pessoas.

## Código da Migração (`lib/deeper/core/data/migrations/create_bx_persons_cmts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateBxPersonsCmtsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_cmts.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_cmts.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_cmts...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_cmts (
      cmt_id INTEGER PRIMARY KEY AUTOINCREMENT,
      cmt_parent_id INTEGER NOT NULL DEFAULT 0,
      cmt_vparent_id INTEGER NOT NULL DEFAULT 0,
      cmt_object_id INTEGER NOT NULL, -- ID do bx_persons_data.id
      cmt_author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do autor
      cmt_level INTEGER NOT NULL DEFAULT 0,
      cmt_text TEXT NOT NULL,
      cmt_mood INTEGER NOT NULL DEFAULT 0,
      cmt_rate INTEGER NOT NULL DEFAULT 0,
      cmt_rate_count INTEGER NOT NULL DEFAULT 0,
      cmt_time INTEGER NOT NULL, -- Unix Timestamp
      cmt_replies INTEGER NOT NULL DEFAULT 0,
      cmt_pinned INTEGER NOT NULL DEFAULT 0,
      cmt_cf INTEGER NOT NULL DEFAULT 1 -- Content Filter
      -- FKs para cmt_object_id -> bx_persons_data.id e cmt_author_id -> sys_profiles.id
      -- poderiam ser adicionadas para integridade referencial.
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_object_parent ON bx_persons_cmts(cmt_object_id, cmt_parent_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_vparent ON bx_persons_cmts(cmt_vparent_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_cmts criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_cmts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_cmts.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_cmts...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_cmts;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_cmts removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_cmts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```