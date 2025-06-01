# Migração Elixir: Criar Tabela `bx_persons_meta_keywords`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_meta_keywords` no banco de dados SQLite. Esta tabela armazena palavras-chave (tags) associadas a perfis de pessoas, útil para busca e categorização.

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_meta_keywords_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsMetaKeywordsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_meta_keywords.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_meta_keywords.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_meta_keywords...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_meta_keywords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id
      keyword TEXT NOT NULL,
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_keywords_object_id ON bx_persons_meta_keywords(object_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_keywords_keyword ON bx_persons_meta_keywords(keyword);
    -- Para evitar duplicatas de keyword por objeto:
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_meta_keywords_object_keyword ON bx_persons_meta_keywords(object_id, keyword);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_meta_keywords criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_meta_keywords: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_meta_keywords.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_meta_keywords...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_meta_keywords;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_meta_keywords removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_meta_keywords: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `object_id`: `INT` (MySQL) -> `INTEGER` (SQLite).
*   `keyword`: `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite).
*   **Índice Único:** Adicionado `uidx_bx_persons_meta_keywords_object_keyword` para garantir que uma palavra-chave não seja associada múltiplas vezes ao mesmo perfil.
*   **Chave Estrangeira:** Definida para `object_id`.