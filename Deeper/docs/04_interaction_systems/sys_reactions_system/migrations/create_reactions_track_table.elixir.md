# Migração Elixir: Criar Tabela de Rastreamento de Reações (Genérica)

Este módulo de migração Elixir cria uma tabela genérica de exemplo para o rastreamento de reações individuais, chamada `generic_reactions_track`. O nome real da tabela seria definido em `sys_objects_reaction.table_track`.

## Código da Migração (`lib/deeper/core/data/migrations/create_generic_reactions_track_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateGenericReactionsTrackTable do
  @moduledoc \"\"\"
  Migração para criar a tabela genérica de rastreamento de reações.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    table_name = \"generic_reactions_track\" # Ou o nome que será usado
    Logger.info(\"Criando tabela #{table_name}...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{table_name} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL,
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id)
      reaction_type TEXT NOT NULL,
      date INTEGER NOT NULL, -- Unix Timestamp
      UNIQUE (object_id, author_id) -- Um usuário só pode ter uma reação por objeto
      -- FOREIGN KEY (object_id) REFERENCES some_content_table(id) ON DELETE CASCADE
      -- FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_obj_author ON #{table_name}(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_obj_type ON #{table_name}(object_id, reaction_type);
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_author_obj ON #{table_name}(author_id, object_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{table_name} criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela #{table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    table_name = \"generic_reactions_track\"
    Logger.info(\"Removendo tabela #{table_name}...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS #{table_name};\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela #{table_name} removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela #{table_name}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas:

*   Esta tabela rastreia qual `author_id` deu qual `reaction_type` a qual `object_id`.
*   A restrição `UNIQUE (object_id, author_id)` garante que um usuário só possa ter uma reação ativa por objeto. Se o usuário mudar sua reação, o registro existente é atualizado (ou deletado e um novo inserido).