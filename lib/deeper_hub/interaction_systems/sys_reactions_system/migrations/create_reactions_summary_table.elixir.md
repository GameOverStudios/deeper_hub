# Migração Elixir: Criar Tabela de Sumário de Reações (Genérica)

Este módulo de migração Elixir cria uma tabela genérica de exemplo para o sumário de reações, chamada `generic_reactions_summary`. O nome real da tabela seria definido em `sys_objects_reaction.table_main`.

## Código da Migração (`lib/deeper/core/data/migrations/create_generic_reactions_summary_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateGenericReactionsSummaryTable do
  @moduledoc \"\"\"
  Migração para criar a tabela genérica de sumário de reações.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    table_name = \"generic_reactions_summary\" # Ou o nome que será usado
    Logger.info(\"Criando tabela #{table_name}...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{table_name} (
      object_id INTEGER NOT NULL,
      reaction_type TEXT NOT NULL, -- 'like', 'love', etc.
      count INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (object_id, reaction_type)
      -- FOREIGN KEY (object_id) REFERENCES some_content_table(id) ON DELETE CASCADE -- Deve ser definido pelo módulo de conteúdo
    );
    CREATE INDEX IF NOT EXISTS idx_#{table_name}_object_id ON #{table_name}(object_id);
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
    table_name = \"generic_reactions_summary\"
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

*   Esta tabela armazena a contagem total para cada `reaction_type` em um `object_id` específico.
*   A chave primária composta `(object_id, reaction_type)` garante uma única entrada de contagem por reação em um objeto.