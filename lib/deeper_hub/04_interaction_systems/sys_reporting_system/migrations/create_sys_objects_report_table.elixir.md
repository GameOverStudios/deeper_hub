# Migração Elixir: Criar Tabela `sys_objects_report`

Este módulo de migração Elixir é responsável por criar a tabela `sys_objects_report` no banco de dados SQLite. Esta tabela de configuração define cada \"objeto de denúncia\" para diferentes tipos de conteúdo no UNA, especificando as tabelas de dados, comportamento e triggers.

## Código da Migração (`lib/deeper/interaction_systems/reporting/migrations/create_sys_objects_report_table.ex`)

```elixir
defmodule Deeper.InteractionSystems.Reporting.Migrations.CreateSysObjectsReportTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_objects_report.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_objects_report.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_objects_report...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_objects_report (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      table_main TEXT NOT NULL, -- Tabela de sumário das denúncias
      table_track TEXT NOT NULL, -- Tabela de rastreamento de denúncias
      pruning INTEGER NOT NULL DEFAULT 31536000, -- 1 ano em segundos
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      base_url TEXT,
      object_comment TEXT, -- Nome de um objeto sys_objects_cmts para comentários nas denúncias
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT,
      trigger_field_count TEXT, -- Coluna para contagem de denúncias
      class_name TEXT,
      class_file TEXT
      -- FK para Module (sys_modules.name)
      -- FK para object_comment (sys_objects_cmts.Name)
    );

    CREATE INDEX IF NOT EXISTS idx_sys_objects_report_name ON sys_objects_report(name);
    CREATE INDEX IF NOT EXISTS idx_sys_objects_report_module ON sys_objects_report(Module);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_report criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_objects_report: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_objects_report.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_objects_report...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_objects_report;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_objects_report removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_objects_report: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT`.
*   Colunas `VARCHAR` e `TEXT` do MySQL -> `TEXT` no SQLite. `name` é `UNIQUE`.
*   Colunas `INT` e `TINYINT` do MySQL -> `INTEGER` no SQLite.