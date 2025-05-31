# Migração Elixir: Criar Tabela `sys_localization_categories`

Este módulo de migração Elixir é responsável por criar a tabela `sys_localization_categories` no banco de dados SQLite. Esta tabela agrupa chaves de tradução, geralmente por módulo ou área funcional do sistema, para melhor organização.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_localization_categories_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysLocalizationCategoriesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_localization_categories.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_localization_categories.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_localization_categories...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_localization_categories (
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      Name TEXT NOT NULL UNIQUE -- Nome da categoria, ex: 'System', 'bx_persons'
    );

    CREATE INDEX IF NOT EXISTS idx_sys_localization_categories_name ON sys_localization_categories(Name);
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_categories criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_localization_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_localization_categories.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_localization_categories...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_localization_categories;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_localization_categories removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_localization_categories: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `ID`: `INT(6) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `Name`: `VARCHAR(255)` (MySQL) -> `TEXT` (SQLite). `Name` é `UNIQUE`.