# Migração Elixir: Criar Tabela `bx_persons_reports_track`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_reports_track` no banco de dados SQLite. Esta tabela rastreia as denúncias feitas contra perfis de pessoas.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_reports_track_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsReportsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_reports_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_reports_track.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_reports_track...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_reports_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil denunciado)
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem denunciou)
      author_nip INTEGER, -- IP do autor como inteiro
      type TEXT NOT NULL DEFAULT '', -- Tipo da denúncia
      \"text\" TEXT NOT NULL, -- Detalhes da denúncia (no UNA era text NOT NULL DEFAULT '')
      date INTEGER NOT NULL, -- Unix Timestamp
      checked_by INTEGER DEFAULT 0, -- ID do admin que verificou (FK para sys_profiles.id ou sys_accounts.id)
      status INTEGER NOT NULL DEFAULT 0, -- Status da denúncia (TINYINT)
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- FK para checked_by (sys_profiles.id) pode ser adicionada se 0 não for um valor válido.
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_object_author_nip ON bx_persons_reports_track(object_id, author_nip); -- O original é (object_id, author_id, author_nip) mas author_id já tem FK
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_author_id ON bx_persons_reports_track(author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_checked_by ON bx_persons_reports_track(checked_by) WHERE checked_by != 0;
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_reports_track criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_reports_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_reports_track.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_reports_track...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_reports_track;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_reports_track removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_reports_track: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `object_id`, `author_id`, `author_nip`, `date`, `checked_by`, `status`: `INT` ou `TINYINT` (MySQL) -> `INTEGER` (SQLite). `date` é Unix Timestamp.
*   `type`, `text`: `VARCHAR` ou `TEXT` (MySQL) -> `TEXT` (SQLite). A coluna `text` foi referenciada como `\"text\"` para evitar conflito.
*   **Chaves Estrangeiras:** Definidas para `object_id` e `author_id`. `checked_by` também poderia ser uma FK para `sys_profiles.id` (ou `sys_accounts.id`) se `0` não for um valor válido para \"não verificado\".