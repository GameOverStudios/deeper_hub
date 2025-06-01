# Migração Elixir: (Exemplo) Criar Tabela de Rastreamento de Votos (`example_votes_track`)

Este módulo de migração Elixir é um **exemplo** de como uma tabela de rastreamento de votos individuais (referenciada por `sys_objects_vote.TableTrack`) seria criada. O nome real da tabela (aqui `example_votes_track`) é dinâmico.

Por exemplo, para o objeto de voto `bx_persons_ratings`, a `TableTrack` poderia ser `bx_persons_votes_track`.

**Dependências:** `sys_profiles` (para `author_id`)

## Código da Migração (`lib/deeper/interaction_systems/voting/migrations/create_example_votes_track_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Voting.Migrations.CreateExampleVotesTrackTable do
  @moduledoc \"\"\"
  Migração EXEMPLO para criar uma tabela de rastreamento de votos.
  O nome real da tabela viria de sys_objects_vote.TableTrack.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @table_name \"example_votes_track\" # Este nome seria dinâmico

  @doc \"\"\"
  Executa a migração para criar a tabela de exemplo.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de exemplo de rastreamento de votos: #{@table_name}...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- ID do item de conteúdo votado
      author_id INTEGER NOT NULL, -- FK para sys_profiles.id
      author_nip INTEGER NOT NULL, -- IP do autor como inteiro
      value INTEGER NOT NULL, -- O valor do voto (ex: 1-5)
      date INTEGER NOT NULL, -- Unix Timestamp
      FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
      -- A FK para object_id dependeria do tipo de conteúdo.
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_#{@table_name}_object_author ON #{@table_name}(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);
    CREATE INDEX IF NOT EXISTS idx_#{@table_name}_author_id ON #{@table_name}(author_id);
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

*   `value`: `TINYINT(4)` (MySQL) -> `INTEGER`. Uma `CHECK` constraint (ex: `CHECK(value >= 1 AND value <= 5)`) pode ser adicionada com base em `sys_objects_vote.MinValue` e `MaxValue`.
*   O índice `UNIQUE` em `(object_id, author_id)` é crucial para garantir que um usuário vote apenas uma vez no mesmo item (a menos que `IsUndo` permita alterar o voto, o que seria um `UPDATE`).