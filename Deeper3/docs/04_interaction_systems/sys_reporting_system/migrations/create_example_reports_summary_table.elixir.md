# Migração Elixir: (Exemplo) Criar Tabela de Sumário de Denúncias (`example_reports_summary`)

Este módulo de migração Elixir é um **exemplo** de como uma tabela de sumário de denúncias (referenciada por `sys_objects_report.table_main`) seria criada. O nome real da tabela (aqui `example_reports_summary`) é dinâmico.

Por exemplo, para o objeto de denúncia `bx_persons_reports`, a `table_main` poderia ser `bx_persons_reports` (a própria tabela de sumário).

## Código da Migração (`lib/deeper/interaction_systems/reporting/migrations/create_example_reports_summary_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Reporting.Migrations.CreateExampleReportsSummaryTable do
  @moduledoc \"\"\"
  Migração EXEMPLO para criar uma tabela de sumário de denúncias.
  O nome real da tabela viria de sys_objects_report.table_main.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @table_name \"example_reports_summary\" # Este nome seria dinâmico

  @doc \"\"\"
  Executa a migração para criar a tabela de exemplo.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela de exemplo de sumário de denúncias: #{@table_name}...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS #{@table_name} (
      -- No UNA, bx_persons_reports tem: id (PK), object_id (UNIQUE), count
      -- Para consistência com uma tabela de sumário 1:1 com o objeto, object_id pode ser PK.
      object_id INTEGER PRIMARY KEY NOT NULL, -- ID do item de conteúdo denunciado
      count INTEGER NOT NULL DEFAULT 0 -- Número total de denúncias
      -- A FK para object_id dependeria do tipo de conteúdo específico.
    );
    \"\"\"
    # Se object_id não for PK, mas ainda assim único por objeto:
    # CREATE TABLE IF NOT EXISTS #{@table_name} (
    #   id INTEGER PRIMARY KEY AUTOINCREMENT,
    #   object_id INTEGER NOT NULL UNIQUE,
    #   count INTEGER NOT NULL DEFAULT 0
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

*   A estrutura da tabela `table_main` no UNA pode variar. O exemplo `bx_persons_reports` usa `object_id` como `UNIQUE` e tem um `id` PK separado. Para SQLite, fazer `object_id` ser a `PRIMARY KEY` é uma opção limpa para tabelas de sumário 1:1.