# Migração Elixir: Criar Tabela `bx_persons_meta_mentions`

Este módulo de migração Elixir é responsável por criar a tabela `bx_persons_meta_mentions` no banco de dados SQLite. Esta tabela rastreia menções a perfis de pessoas dentro de outros conteúdos (ou em descrições de perfis, comentários, etc.).

**Dependências:** `sys_profiles`

## Código da Migração (`lib/deeper/content/persons/migrations/create_bx_persons_meta_mentions_table.ex`)

```elixir
defmodule Deeper.Content.Persons.Migrations.CreateBxPersonsMetaMentionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela bx_persons_meta_mentions.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela bx_persons_meta_mentions.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela bx_persons_meta_mentions...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS bx_persons_meta_mentions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil/conteúdo ONDE a menção ocorre)
      profile_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil QUE FOI mencionado)
      FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_mentions_object_id ON bx_persons_meta_mentions(object_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_meta_mentions_profile_id ON bx_persons_meta_mentions(profile_id);
    -- Para evitar múltiplas menções idênticas do mesmo profile no mesmo objeto:
    CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_meta_mentions_object_profile ON bx_persons_meta_mentions(object_id, profile_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_meta_mentions criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela bx_persons_meta_mentions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela bx_persons_meta_mentions.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela bx_persons_meta_mentions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS bx_persons_meta_mentions;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela bx_persons_meta_mentions removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela bx_persons_meta_mentions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `object_id`, `profile_id`: `INT` (MySQL) -> `INTEGER` (SQLite).
*   **Índice Único:** Adicionado `uidx_bx_persons_meta_mentions_object_profile` para evitar registrar a mesma menção (mesmo perfil mencionado no mesmo objeto) múltiplas vezes.
*   **Chaves Estrangeiras:** Definidas para `object_id` e `profile_id`, ambas referenciando `sys_profiles.id`.