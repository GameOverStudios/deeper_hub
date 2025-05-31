# Migração Elixir: Criar Tabela `sys_options_types`

Este módulo de migração Elixir é responsável por criar a tabela `sys_options_types` no banco de dados SQLite. Esta tabela agrupa categorias de opções, como \"Sistema\", \"Módulos\", etc., para organização no painel de administração do UNA.

## Código da Migração (`lib/deeper/core/data/migrations/create_sys_options_types_table.ex`)

```elixir
defmodule Deeper.Core.Data.Migrations.CreateSysOptionsTypesTable do
  @moduledoc \"\"\"
  Migração para criar a tabela sys_options_types.
  \"\"\"

  alias Deeper.Core.Data.Repo
  alias Deeper.Core.Logger
  require Deeper.Core.Logger

  @doc \"\"\"
  Executa a migração para criar a tabela sys_options_types.
  \"\"\"
  @spec up() :: :ok | {:error, any()}
  def up do
    Logger.info(\"Criando tabela sys_options_types...\", module: __MODULE__)

    sql = \"\"\"
    CREATE TABLE IF NOT EXISTS sys_options_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      \"group\" TEXT NOT NULL,
      name TEXT NOT NULL UNIQUE,
      caption TEXT NOT NULL,
      icon TEXT,
      \"order\" INTEGER DEFAULT 0
    );
    \"\"\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_types criada com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao criar tabela sys_options_types: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Reverte a migração, removendo a tabela sys_options_types.
  \"\"\"
  @spec down() :: :ok | {:error, any()}
  def down do
    Logger.info(\"Removendo tabela sys_options_types...\", module: __MODULE__)

    sql = \"DROP TABLE IF EXISTS sys_options_types;\"

    case Repo.execute(sql) do
      {:ok, _} ->
        Logger.info(\"Tabela sys_options_types removida com sucesso.\", module: __MODULE__)
        :ok
      {:error, reason} ->
        Logger.error(\"Falha ao remover tabela sys_options_types: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

## Notas de Adaptação SQLite:

*   `id`: `INT(11) UNSIGNED AUTO_INCREMENT` (MySQL) -> `INTEGER PRIMARY KEY AUTOINCREMENT` (SQLite).
*   `group`, `name`, `caption`, `icon`: `VARCHAR` (MySQL) -> `TEXT` (SQLite). `name` é `UNIQUE`.
*   `order`: `INT(11)` (MySQL) -> `INTEGER` (SQLite). Colocado entre aspas (`\"order\"`) para evitar conflito com a palavra reservada SQL.