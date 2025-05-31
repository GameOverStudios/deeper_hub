# Migração Elixir: Criar Tabela `deeper_polls`

Este módulo de migração Elixir é responsável por criar a tabela `deeper_polls` no banco de dados SQLite. Esta tabela armazena as informações principais sobre as enquetes criadas pelos usuários.

## Código da Migração (`lib/deeper/core/data/migrations/create_deeper_polls_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateDeeperPollsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela deeper_polls.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela deeper_polls.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela deeper_polls...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS deeper_polls (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      question TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      description TEXT,
      allow_multiple_choices INTEGER NOT NULL DEFAULT 0,
      results_visibility TEXT NOT NULL DEFAULT 'after_vote'
        CHECK(results_visibility IN ('always', 'after_vote', 'after_close', 'owner_only')),
      closes_at INTEGER,
      status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'closed', 'draft')),
      total_votes_count INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_dp_profile_id ON deeper_polls(profile_id);
    CREATE INDEX IF NOT EXISTS idx_dp_slug ON deeper_polls(slug);
    CREATE INDEX IF NOT EXISTS idx_dp_status ON deeper_polls(status);
    CREATE INDEX IF NOT EXISTS idx_dp_closes_at ON deeper_polls(closes_at);
    \"\"\"

    # Repo.execute(\"PRAGMA foreign_keys = ON;\") -- Se necessário

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_polls criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela deeper_polls: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela deeper_polls.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela deeper_polls...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS deeper_polls;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela deeper_polls removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela deeper_polls: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Depende da existência de `sys_profiles`.
*   `ON DELETE CASCADE` para `profile_id` significa que se o perfil do criador for excluído, suas enquetes também serão.
*   As `CHECK` constraints são usadas para `results_visibility` e `status` para garantir valores válidos.