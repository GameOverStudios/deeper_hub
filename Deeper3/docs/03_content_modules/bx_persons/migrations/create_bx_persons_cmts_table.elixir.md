# Migração Elixir: Criar Tabela `bx_persons_cmts` (Condicional)

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_cmts` no banco de dados SQLite. Esta tabela seria usada se o sistema UNA configurado utilizasse um sistema de comentários dedicado especificamente para o módulo `bx_persons`, em vez do sistema de comentários genérico (`sys_cmts_*`).

**Nota Importante:** Se o sistema UNA utiliza o sistema de comentários genérico (`sys_objects_cmts` configurado para `bx_persons` ou `bx_persons_notes`), esta migração e tabela **não são necessárias**. A API de comentários seria gerenciada através da seção `04_interaction_systems/sys_comments_system/`. Esta migração é fornecida para completude, caso um esquema legado ou customizado do UNA esteja em uso.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_cmts_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsCmtsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_cmts (se aplicável).
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_cmts.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_cmts (condicional)...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
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

## Notas de Adaptação SQLite:

*   Todas as colunas `INT` ou `TINYINT` do MySQL são mapeadas para `INTEGER` no SQLite.
*   `cmt_text`: `TEXT` (MySQL) -> `TEXT` (SQLite).
*   `cmt_time`: Armazenado como Timestamp Unix (`INTEGER`).
*   **Chaves Estrangeiras:**
    *   `cmt_object_id` para `sys_profiles.id`.
    *   `cmt_author_id` para `sys_profiles.id`. `ON DELETE SET NULL` é uma opção se um comentário puder existir sem um autor (ex: se o autor for deletado), ou `ON DELETE RESTRICT` se o autor for mandatório.
*   **Full-text Search:** Se a busca full-text em `cmt_text` for necessária, as extensões FTS do SQLite devem ser usadas em vez do `FULLTEXT KEY` do MySQL.