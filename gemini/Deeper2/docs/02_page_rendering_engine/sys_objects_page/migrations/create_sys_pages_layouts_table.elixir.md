# Migração Elixir: Criar Tabela `sys_pages_layouts`

Este módulo de migração Elixir é responsável por criar a tabela `sys_pages_layouts` no banco de dados SQLite. Esta tabela define as diferentes estruturas de layout (ex: 1 coluna, 2 colunas, etc.) que podem ser aplicadas às páginas do sistema.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_pages_layouts_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysPagesLayoutsTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_pages_layouts.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_pages_layouts.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_pages_layouts...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_pages_layouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      icon TEXT NOT NULL,
      title TEXT NOT NULL,
      template TEXT NOT NULL, -- Nome do arquivo de template HTML
      cells_number INTEGER NOT NULL -- Número de células/colunas
    );

    CREATE INDEX IF NOT EXISTS idx_sys_pages_layouts_name ON sys_pages_layouts(name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_layouts criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_pages_layouts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_pages_layouts.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_pages_layouts...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_pages_layouts;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_pages_layouts removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_pages_layouts: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11)` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `name`, `icon`, `title`, `template`: `VARCHAR` (MySQL) -> `TEXT` (SQLite). `name` é `UNIQUE`.
*   `cells_number`: `INT(11)` (MySQL) -> `INTEGER` (SQLite).