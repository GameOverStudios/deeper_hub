# Migração Elixir: (Exemplo) Criar Tabela de Rastreamento de Scores (`example_scores_track`)

Este módulo de migração Elixir é um **exemplo** de como uma tabela de rastreamento de scores individuais (referenciada por `sys_objects_score.table_track`) seria criada. O nome real da tabela (aqui `example_scores_track`) é dinâmico.

Por exemplo, para o objeto de score `bx_persons_scores`, a `table_track` poderia ser `bx_persons_scores_track`.

**Dependências:** `sys_profiles` (para `author_id`)

## Código da Migração (`lib/deeper/interaction_systems/scoring/migrations/create_example_scores_track_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Scoring.Migrations.CreateExampleScoresTrackTable do
  @moduledoc \"\"\"
  Migração EXEMPLO para criar uma tabela de rastreamento de scores.
  O nome real da tabela viria de sys_objects_score.table_track.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @table_name \"example_scores_track\" # Este nome seria dinâmico

  @doc \"\"\"
  Executa a migração para criar a tabela de exemplo.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de exemplo de rastreamento de scores: #{@table_name}...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- ID do item de conteúdo pontuado
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id
      author_nip INTEGER NOT NULL, -- IP do autor como inteiro
      type TEXT NOT NULL CHECK(type IN ('up', 'down')), -- 'up' ou 'down'
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- A FK para object_id dependeria do tipo de conteúdo.
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_#{@table_name}_object_author ON #{@table_name}(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_author_id ON #{@table_name}(author_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_type ON #{@table_name}(object_id, type);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{@table_name} criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela #{@table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela de exemplo.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela #{@table_name}...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS #{@table_name};\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{@table_name} removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela #{@table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   `type`: `VARCHAR(8)` no UNA, aqui com `CHECK` constraint para os valores esperados.
*   O índice `UNIQUE` em `(object_id, author_id)` garante que um usuário só possa dar um tipo de score (up OU down) uma vez para o mesmo item. Se o usuário puder mudar de 'up' para 'down', a lógica da aplicação lidaria com um `UPDATE` na coluna `type` desta entrada.