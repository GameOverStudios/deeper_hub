# Migração Elixir: Criar Tabela `sys_objects_report`

Este módulo de migração Elixir cria a tabela `sys_objects_report` no banco de dados SQLite, que armazena as configurações para diferentes instâncias de sistemas de denúncias.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_objects_report_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysObjectsReportTable do
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
      table_main TEXT NOT NULL, -- Tabela de agregação, ex: bx_persons_reports
      table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: bx_persons_reports_track
      pruning INTEGER NOT NULL DEFAULT 0, -- Dias para manter denúncias em track (0 = para sempre)
      is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      base_url TEXT, -- URL base no UNA PHP
      object_comment TEXT, -- Nome do sys_objects_cmts se for para denunciar comentários
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT,
      trigger_field_count TEXT, -- Coluna para contagem de denúncias
      class_name TEXT, -- Específico do UNA PHP
      class_file TEXT -- Específico do UNA PHP
    );
    CREATE INDEX IF NOT EXISTS idx_sys_objects_report_name ON sys_objects_report(name);
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

## Notas:

*   `name`: Identificador único para o sistema de denúncias (ex: `bx_persons`).
*   `table_main`: Nome da tabela SQL que armazena os dados agregados das denúncias.
*   `table_track`: Nome da tabela SQL que armazena as denúncias individuais.
*   `trigger_table`, `trigger_field_count`: Usados para atualizar o contador de denúncias na tabela do conteúdo pai.