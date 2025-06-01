# Migração Elixir: (Exemplo) Criar Tabela de Sumário de Scores (`example_scores_summary`)

Este módulo de migração Elixir é um **exemplo** de como uma tabela de sumário de scores (referenciada por `sys_objects_score.table_main`) seria criada. O nome real da tabela (aqui `example_scores_summary`) é dinâmico.

Por exemplo, para o objeto de score `bx_persons_scores`, a `table_main` poderia ser `bx_persons_scores` (a tabela de sumário).

## Código da Migração (`lib/deeper/interaction_systems/scoring/migrations/create_example_scores_summary_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Scoring.Migrations.CreateExampleScoresSummaryTable do
  @moduledoc \"\"\"
  Migração EXEMPLO para criar uma tabela de sumário de scores.
  O nome real da tabela viria de sys_objects_score.table_main.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @table_name \"example_scores_summary\" # Este nome seria dinâmico

  @doc \"\"\"
  Executa a migração para criar a tabela de exemplo.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de exemplo de sumário de scores: #{@table_name}...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      -- No UNA, bx_persons_scores tem: id (PK), object_id (UNIQUE), count_up, count_down
      object_id INTEGER PRIMARY KEY NOT NULL, -- ID do item de conteúdo que foi pontuado
      count_up INTEGER NOT NULL DEFAULT 0, -- Número total de upvotes
      count_down INTEGER NOT NULL DEFAULT 0 -- Número total de downvotes
      -- A FK para object_id dependeria do tipo de conteúdo específico.
    );
    \"\"\"
    # Se object_id não for PK:
    # CREATE TABLE IF NOT EXISTS #{@table_name} (
    #   id INTEGER PRIMARY KEY AUTOINCREMENT,
    #   object_id INTEGER NOT NULL UNIQUE,
    #   count_up INTEGER NOT NULL DEFAULT 0,
    #   count_down INTEGER NOT NULL DEFAULT 0
    # );
    # CREATE INDEX IF NOT EXISTS idx_#{@table_name}_object_id ON #{@table_name}(object_id);


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

*   A estrutura da tabela `table_main` no UNA (ex: `bx_persons_scores`) usa `object_id` como `UNIQUE` e tem um `id` PK separado. Para SQLite, fazer `object_id` ser a `PRIMARY KEY` é uma opção limpa para tabelas de sumário 1:1.