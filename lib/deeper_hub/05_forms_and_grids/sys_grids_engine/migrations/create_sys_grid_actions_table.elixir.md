# Migração Elixir: Criar Tabela `sys_grid_actions`

Este módulo de migração Elixir é responsável por criar a tabela `sys_grid_actions` no banco de dados SQLite. Esta tabela define as ações disponíveis para um grid específico (definido em `sys_objects_grid`), como ações em massa, ações por linha ou ações independentes.

**Dependências:** `sys_objects_grid`

## Código da Migração (`lib/deeper/grids/migrations/create_sys_grid_actions_table.ex`)

```elixir
defmodule Deeper.Grids.Migrations.CreateSysGridActionsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_grid_actions.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_grid_actions.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_grid_actions...\", module: __MODULE__)
    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_grid_actions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL, -- FK para sys_objects_grid.object
      type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')),
      name TEXT NOT NULL, -- Nome da ação, ex: 'delete', 'edit'
      title TEXT, -- Título da ação (pode ser chave de linguagem)
      icon TEXT,
      icon_only INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
      confirm INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se requer confirmação)
      active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
      \"order\" INTEGER NOT NULL,
      FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_grid_actions_object_type_name ON sys_grid_actions(object, type, name);
    CREATE INDEX IF NOT EXISTS idx_sys_grid_actions_object_order ON sys_grid_actions(object, \"order\");
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_grid_actions criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_grid_actions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_grid_actions.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_grid_actions...\", module: __MODULE__)
    sql = \"DROP TABLE IF EXISTS sys_grid_actions;\"
    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_grid_actions removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_grid_actions: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`, `order`: `INT(11)` (MySQL) -> `INTEGER`. `id` é `PK AUTOINCREMENT`. `\"order\"` está entre aspas.
*   `object`, `name`, `title`, `icon`: `VARCHAR` (MySQL) -> `TEXT`.
*   `type`: `ENUM` (MySQL) -> `TEXT` com `CHECK` constraint.
*   `icon_only`, `confirm`, `active`: `TINYINT(4)` (MySQL) -> `INTEGER` (0 ou 1).
*   **Índice Único:** `uidx_sys_grid_actions_object_type_name` garante que uma combinação de grid, tipo de ação e nome de ação seja única.
*   **Chave Estrangeira:** `object` para `sys_objects_grid.object`.