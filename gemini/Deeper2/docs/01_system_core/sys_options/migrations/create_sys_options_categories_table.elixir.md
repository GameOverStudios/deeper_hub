# Migração Elixir: Criar Tabela `sys_options_categories`

Este módulo de migração Elixir é responsável por criar a tabela `sys_options_categories` no banco de dados SQLite. Esta tabela define categorias para agrupar opções do sistema (ex: \"Geral\", \"Segurança\") e está ligada a `sys_options_types`.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_options_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysOptionsCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_options_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_options_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_options_categories...\", module: __MODULE__)

    # PRAGMA foreign_keys = ON;

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type_id INTEGER NOT NULL,
      name TEXT NOT NULL UNIQUE,
      caption TEXT NOT NULL,
      hidden INTEGER NOT NULL DEFAULT 0, -- 0 for false, 1 for true
      \"order\" INTEGER DEFAULT 0,
      FOREIGN KEY (type_id) REFERENCES sys_options_types(id) ON DELETE CASCADE ON UPDATE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_sys_options_categories_type_id ON sys_options_categories(type_id);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_options_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_options_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_options_categories...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_options_categories;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_options_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `type_id`: `INT(11) UNSIGNED` (MySQL) -> `INTEGER` (SQLite). É uma chave estrangeira para `sys_options_types.id`.
*   `name`, `caption`: `VARCHAR(64)` (MySQL) -> `TEXT` (SQLite). `name` é `UNIQUE`.
*   `hidden`: `TINYINT(1)` (MySQL) -> `INTEGER` (SQLite), (0 para false, 1 para true).
*   `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). Colocado entre aspas (`\"order\"`).
*   **Chave Estrangeira:** Definida para `type_id`.